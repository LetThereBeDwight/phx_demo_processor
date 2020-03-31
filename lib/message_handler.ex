defmodule PhxDemoProcessor.MessageHandler do
  use GenServer

  def message_processing_rate, do: System.get_env("MSG_PROCESS_RATE", "1000") |> Integer.parse |> Tuple.to_list |> List.first# Limit Message Rate to 1 per second

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  def init(state) do
    {:ok, state}
  end

  def receive_message(queue_name, message, server_pid \\ __MODULE__) do
    GenServer.cast(server_pid, {:receive_message, queue_name, message})
  end

  def start_listen_to_message_processes(listener_pid, server_pid \\ __MODULE__) do
    GenServer.cast(server_pid, {:new_message_listener, listener_pid})
  end

  def stop_listen_to_message_processes(listener_pid, server_pid \\ __MODULE__) do
    GenServer.cast(server_pid, {:remove_message_listener, listener_pid})
  end

  defp process_message(message), do: IO.puts(message)

  def handle_cast({:new_message_listener, new_message_listener}, state) do
    new_set = Map.get(state, "listeners", MapSet.new()) |>
              MapSet.put(new_message_listener)

    {:noreply, Map.put(state, "listeners", new_set)}
  end

  def handle_cast({:remove_message_listener, old_message_listener}, state) do
    new_set = Map.get(state, "listeners", MapSet.new()) |>
              MapSet.delete(old_message_listener)

    {:noreply, Map.put(state, "listeners", new_set)}
  end

  def handle_cast({:receive_message, queue_name, message}, state) do
    q = Map.get(state, queue_name, :queue.new())
    if !Map.has_key?(state, queue_name) do
      # Assuming the first message can be immediately processed,
      # We can handle rate limiting through the queue processor.
      # If we don't want to process the first message immediately,
      # use Process.send_after
      send(self(), {:process_queue, queue_name})
    end

    {:noreply, Map.put(state, queue_name, :queue.in(message, q))}
  end

  def handle_info({:process_queue, queue_name}, state) do
    case :queue.out(Map.get(state, queue_name)) do
      {{:value, message}, q} ->
        spawn(fn ->
          Enum.each(Map.get(state, "listeners", MapSet.new()),
            fn pid ->
              send(pid, {:processing_message, queue_name, message})
            end
          )
        end)
        spawn(fn -> process_message(message) end)
        if :queue.is_empty(q) do
          Process.send_after(self(), {:empty_queue, queue_name}, message_processing_rate())
        else
          Process.send_after(self(), {:process_queue, queue_name}, message_processing_rate())
        end
        {:noreply, Map.put(state, queue_name, q)}
    end
  end

  def handle_info({:empty_queue, queue_name}, state) do
    if :queue.is_empty(Map.get(state, queue_name)) do
      {:noreply, Map.delete(state, queue_name)}
    else
      send(self(), {:process_queue, queue_name})
      {:noreply, state}
    end
  end

end

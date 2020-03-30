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

  defp process_message(message), do: IO.puts(message)

  def handle_cast({:receive_message, queue_name, message}, state) do
    if Map.has_key?(state, queue_name) do
      q = Map.get(state, queue_name)
      {:noreply, Map.put(state, queue_name, :queue.in(message, q))}
    else
      # Assuming the first message can be immediately processed,
      # We can handle rate limiting through the queue processor.
      # If we don't want to process the first message immediately,
      # use Process.send_after
      send(self(), {:process_queue, queue_name})
      q = :queue.new()
      {:noreply, Map.put(state, queue_name, :queue.in(message, q))}
    end
  end

  def handle_info({:process_queue, queue_name}, state) do
    case :queue.out(Map.get(state, queue_name)) do
      {{:value, message}, q} ->
        spawn(fn -> process_message(message) end)
        Process.send_after(self(), {:process_queue, queue_name}, message_processing_rate())
        {:noreply, Map.put(state, queue_name, q)}
      {:empty, _} ->
        {:noreply, Map.delete(state, queue_name)}
    end
  end

end

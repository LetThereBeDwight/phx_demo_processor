defmodule PhxDemoProcessor.MessageHandler do
  use GenServer

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  def init(state) do
    {:ok, state}
  end

  def receive_message(queue_name, message, pid \\ __MODULE__) do
    GenServer.cast(pid, {:receive_message, queue_name, message})
  end

  def get_queue(name) do
    :ok
  end

  defp process_message(message), do: IO.puts(message)

  def handle_cast({:receive_message, queue_name, message}, state) do
    if Map.has_key?(state, queue_name) do
      q = Map.get(state, queue_name)
      {:noreply, Map.put(state, queue_name, :queue.in(message, q))}
    else
      Process.send_after(self(), {:process_queue, queue_name}, 1000)
      q = :queue.new
      {:noreply, Map.put(state, queue_name, :queue.in(message, q))}
    end
  end

  def handle_info({:process_queue, queue_name}, state) do
    {{:value, message}, q} =
      Map.get(state, queue_name) |>
      :queue.out()

    spawn(fn -> process_message(message) end)

    if :queue.is_empty(q) do
      {:noreply, Map.delete(state, queue_name)}
    else
      Process.send_after(self(), {:process_queue, queue_name}, 1000)
      {:noreply, Map.put(state, queue_name, q)}
    end
  end

end

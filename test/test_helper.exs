ExUnit.start()

defmodule PhxDemoProcessor.MonitorProcessHelper do
  import ExUnit.Assertions
  def monitor_processing(counts, last_processing_times \\ Map.new()) do
    handler_pid = Process.whereis(PhxDemoProcessor.MessageHandler)
    :erlang.trace(handler_pid, true, [:receive])

    {counts, process_times} =
      receive do
        {:trace, ^handler_pid, :receive, {:process_queue, queue_name}} when :erlang.is_map_key(queue_name, counts) ->
          time = System.monotonic_time(:millisecond)
          if Map.has_key?(last_processing_times, queue_name) do
            assert time - Map.get(last_processing_times, queue_name) >= 1000
          end

          { Map.put(counts, queue_name, Map.get(counts, queue_name) - 1),
            Map.put(last_processing_times, queue_name, time) }
      end

    still_counting = Enum.reduce(counts, 0, fn {_k, v}, acc -> v + acc end)
    if still_counting > 0 do
      monitor_processing(counts, process_times)
    end
  end
end

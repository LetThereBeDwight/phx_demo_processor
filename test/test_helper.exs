ExUnit.start()

defmodule PhxDemoProcessor.MonitorProcessHelper do
  import ExUnit.Assertions

  def monitor_queue_processing(queue_name, messages, last_processing_time \\ nil) do
    PhxDemoProcessor.MessageHandler.start_listen_to_message_processes(self())

    [expected_message | remaining] = messages
    process_time =
      receive do
        {:processing_message, ^queue_name, message} ->
          assert expected_message == message
          time = System.monotonic_time(:millisecond)
          if last_processing_time do
            # Should be 1000 but a microsecond difference could be reasonable
            # via accounting errors
            assert time - last_processing_time >= 999
          end
          time
      end

    PhxDemoProcessor.MessageHandler.stop_listen_to_message_processes(self())
    if List.first(remaining) do
      monitor_queue_processing(queue_name, remaining, process_time)
    end

    :ok
  end
end

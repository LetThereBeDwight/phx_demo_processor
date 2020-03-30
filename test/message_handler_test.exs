defmodule PhxDemoProcessor.MessageHandlerTest do
  use ExUnit.Case
  alias PhxDemoProcessor.MessageHandler

  defp monitor_processing(count, queue_name, last_processing_time \\ nil) do
    handler_pid = Process.whereis(MessageHandler)
    :erlang.trace(handler_pid, true, [:receive])

    process_time =
      receive do
        {:trace, ^handler_pid, :receive, {:process_queue, ^queue_name}} ->
          time = System.monotonic_time(:millisecond)
          if last_processing_time, do: assert time - last_processing_time >= 1000
          time
      end

    if count > 1 do
      monitor_processing(count - 1, queue_name, process_time)
    end
  end

  describe "Test Message Handling Genserver" do
    test "Single Message" do
      assert :ok == MessageHandler.receive_message("TestHandlerQueue", "TestMessageHandler")
    end

    test "Simple Single Queue Rate Limiting" do
      monitor_ref = spawn(fn -> monitor_processing(5, "TestHandlerQueue") end) |>
                    Process.monitor()

      range = 0..4
      for i <- range do
        assert :ok == MessageHandler.receive_message("TestHandlerQueue", "TestMessage_#{i}")
      end

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 6000)
    end
  end
end

defmodule PhxDemoProcessor.MessageHandlerTest do
  use ExUnit.Case
  alias PhxDemoProcessor.MessageHandler

  defp monitor_processing(counts, last_processing_times \\ Map.new()) do
    handler_pid = Process.whereis(MessageHandler)
    :erlang.trace(handler_pid, true, [:receive])

    {counts, process_times} =
      receive do
        {:trace, ^handler_pid, :receive, {:process_queue, queue_name}} when :erlang.is_map_key(queue_name, counts)->
          time = System.monotonic_time(:millisecond)
          if Map.has_key?(last_processing_times, queue_name) do
            assert time - Map.get(last_processing_times, queue_name) >= 1000
          end

          { Map.put(counts, queue_name, Kernel.max(Map.get(counts, queue_name) - 1, 0)),
            Map.put(last_processing_times, queue_name, time) }
      end

    still_counting = Enum.reduce(counts, 0, fn {_k, v}, acc -> v + acc end)
    if still_counting > 0 do
      monitor_processing(counts, process_times)
    end
  end

  describe "Test Message Handling Genserver" do
    test "Single Message" do
      assert :ok == MessageHandler.receive_message("TestHandlerQueueSingle", "TestSingleMessage")
    end

    test "Simple Single Queue Rate Limiting" do
      range = 1..5
      monitor_ref = spawn(fn -> monitor_processing(%{"TestHandlerQueueRate" => Enum.count(range)}) end) |>
                    Process.monitor()

      for i <- range do
        assert :ok == MessageHandler.receive_message("TestHandlerQueueRate", "TestMessage_#{i}")
      end

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 6000)
    end

    test "Simple Multiple Queue Rate Limiting" do
      range_one = 100..105
      range_two = 200..210
      monitor_ref = spawn(fn -> monitor_processing(%{"TestHandlerQueueRateOne" => Enum.count(range_one),
                                                     "TestHandlerQueueRateTwo" => Enum.count(range_two)}) end) |>
                    Process.monitor()

      spawn(fn ->
        for i <- range_one do
          assert :ok == MessageHandler.receive_message("TestHandlerQueueRateOne", "TestMessage_#{i}")
        end
      end)

      spawn(fn ->
        for i <- range_two do
          assert :ok == MessageHandler.receive_message("TestHandlerQueueRateTwo", "TestMessage_#{i}")
        end
      end)

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 12000)
    end

  end
end

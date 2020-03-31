defmodule PhxDemoProcessor.MessageHandlerTest do
  use ExUnit.Case
  import PhxDemoProcessor.MonitorProcessHelper, only: [monitor_processing: 1]
  alias PhxDemoProcessor.MessageHandler

  describe "Test Message Handling Genserver" do
    test "Single Message" do
      assert :ok == MessageHandler.receive_message("TestHandlerQueueSingle", "TestSingleMessage")
    end

    test "Simple Single Queue Rate Limiting" do
      range = 1..5
      monitor_ref = spawn(fn -> monitor_processing(%{"TestHandlerQueueRate" => Enum.count(range)}) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process trace
      for i <- range do
        assert :ok == MessageHandler.receive_message("TestHandlerQueueRate", "TestMessage_#{i}")
      end

      refute_receive({:DOWN, ^monitor_ref, _, _, _}, 4000)
      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 2000)
    end

    test "Simple Multiple Queue Rate Limiting" do
      range_one = 101..105
      range_two = 201..210
      monitor_ref = spawn(fn -> monitor_processing(%{"TestHandlerQueueRateOne" => Enum.count(range_one),
                                                     "TestHandlerQueueRateTwo" => Enum.count(range_two)}) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process trace
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

      refute_receive({:DOWN, ^monitor_ref, _, _, _}, 8000)
      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 2000)
    end

  end
end

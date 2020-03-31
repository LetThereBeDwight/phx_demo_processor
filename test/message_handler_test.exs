defmodule PhxDemoProcessor.MessageHandlerTest do
  use ExUnit.Case
  import PhxDemoProcessor.MonitorProcessHelper, only: [monitor_processing_rate: 1]
  alias PhxDemoProcessor.MessageHandler

  describe "Test Message Handling Genserver" do
    test "Single Message" do
      MessageHandler.start_listen_to_message_processes(self())
      queue_name = Kernel.inspect(make_ref())
      assert :ok == MessageHandler.receive_message(queue_name, "TestSingleMessage")

      receive do
        {:processing_message, ^queue_name, message} ->
          assert message == "TestSingleMessage"
      end
      MessageHandler.stop_listen_to_message_processes(self())
    end

    test "Simple Single Queue Rate Limiting" do
      MessageHandler.start_listen_to_message_processes(self())
      queue_name = Kernel.inspect(make_ref())
      range = 1..5
      monitor_ref = spawn_link(fn -> monitor_processing_rate(%{queue_name => Enum.count(range)}) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process trace
      for i <- range do
        assert :ok == MessageHandler.receive_message(queue_name, "TestSingleQueue_#{i}")
      end

      for i <- range do
        receive do
          {:processing_message, ^queue_name, message} ->
            assert message == "TestSingleQueue_#{i}"
        end
      end

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 10)
      MessageHandler.stop_listen_to_message_processes(self())
    end

    test "Simple Multiple Queue Rate Limiting" do
      MessageHandler.start_listen_to_message_processes(self())
      queue_name_one = Kernel.inspect(make_ref())
      queue_name_two = Kernel.inspect(make_ref())
      range_one = 101..105
      range_two = 201..210
      monitor_ref = spawn_link(fn -> monitor_processing_rate(%{queue_name_one => Enum.count(range_one),
                                                               queue_name_two => Enum.count(range_two)}) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process trace
      spawn_link(fn ->
        for i <- range_one do
          assert :ok == MessageHandler.receive_message(queue_name_one, "TestMessageQueueOne_#{i}")
        end
      end)

      spawn_link(fn ->
        for i <- range_two do
          assert :ok == MessageHandler.receive_message(queue_name_two, "TestMessageQueueTwo_#{i}")
        end
      end)

      for i <- range_one do
        receive do
          {:processing_message, ^queue_name_one, message} ->
            assert message == "TestMessageQueueOne_#{i}"
        end
      end

      for i <- range_two do
        receive do
          {:processing_message, ^queue_name_two, message} ->
            assert message == "TestMessageQueueTwo_#{i}"
        end
      end

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 10)
      MessageHandler.stop_listen_to_message_processes(self())
    end

  end
end

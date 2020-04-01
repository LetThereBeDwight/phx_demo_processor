defmodule PhxDemoProcessor.MessageHandlerTest do
  use ExUnit.Case
  import PhxDemoProcessor.MonitorProcessHelper, only: [monitor_queue_processing: 2]
  alias PhxDemoProcessor.MessageHandler

  describe "Test Message Handling Genserver" do
    test "Single Message" do
      queue_name = Kernel.inspect(make_ref())
      message = Kernel.inspect(make_ref())
      monitor_ref = spawn_link(fn -> monitor_queue_processing(queue_name, [message]) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process link
      assert :ok == MessageHandler.receive_message(queue_name, message)
      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 10)
    end

    test "Simple Single Queue Multiple Messages" do
      queue_name = Kernel.inspect(make_ref())
      range = 1..5
      messages =
        Enum.reduce(range, [], fn _i, acc ->
          [Kernel.inspect(make_ref()) | acc]
        end)

      monitor_ref = spawn_link(fn -> monitor_queue_processing(queue_name, messages) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process link
      Enum.each(messages, fn message ->
        assert :ok == MessageHandler.receive_message(queue_name, message)
      end)

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 4010)
    end

    test "Multiple Queue Multiple Messages" do
      queue_name_one = Kernel.inspect(make_ref())
      queue_name_two = Kernel.inspect(make_ref())

      range_one = 1..5
      range_two = 1..10
      messages_one =
        Enum.reduce(range_one, [], fn _i, acc ->
          [Kernel.inspect(make_ref()) | acc]
        end)

      messages_two =
        Enum.reduce(range_two, [], fn _i, acc ->
          [Kernel.inspect(make_ref()) | acc]
        end)

      monitor_ref_one = spawn_link(fn -> monitor_queue_processing(queue_name_one, messages_one) end)
                        |> Process.monitor()

      monitor_ref_two = spawn_link(fn -> monitor_queue_processing(queue_name_two, messages_two) end)
                        |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process links
      Enum.each(messages_one, fn message ->
        assert :ok == MessageHandler.receive_message(queue_name_one, message)
      end)


      Enum.each(messages_two, fn message ->
        assert :ok == MessageHandler.receive_message(queue_name_two, message)
      end)

      assert_receive({:DOWN, ^monitor_ref_one, _, _, _}, 4010)
      assert_receive({:DOWN, ^monitor_ref_two, _, _, _}, 9010)
    end

  end
end

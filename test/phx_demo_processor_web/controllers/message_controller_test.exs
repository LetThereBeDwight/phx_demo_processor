defmodule PhxDemoProcessorWeb.MessageControllerTest do
  use PhxDemoProcessorWeb.ConnCase
  import PhxDemoProcessor.MonitorProcessHelper, only: [monitor_processing_rate: 1]
  alias PhxDemoProcessor.MessageHandler

  describe "index/2" do
    test "Controller sends a single valid message and gets a 200 text reponse", %{conn: conn} do
      MessageHandler.start_listen_to_message_processes(self())
      queue_name = Kernel.inspect(make_ref())
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => queue_name,
                                                   :message => "TestSingleControllerMessage"}))
        |> text_response(200)

      assert response == "Queue #{queue_name} Message TestSingleControllerMessage"

      receive do
        {:processing_message, ^queue_name, message} ->
          assert message == "TestSingleControllerMessage"
      end
      MessageHandler.stop_listen_to_message_processes(self())
    end

    test "Controller sends multiple valid messages, gets a 200 text reponse, processes rate limited", %{conn: conn} do
      MessageHandler.start_listen_to_message_processes(self())
      queue_name = Kernel.inspect(make_ref())
      range = 1..5

      monitor_ref = spawn_link(fn -> monitor_processing_rate(%{queue_name => Enum.count(range)}) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process trace
      for i <- range do
        response =
          conn
          |> get(Routes.message_path(conn, :index, %{:queue => queue_name,
                                                     :message => "TestMessageControllerRate_#{i}"}))
          |> text_response(200)

        assert response == "Queue #{queue_name} Message TestMessageControllerRate_#{i}"
      end

      for i <- range do
        receive do
          {:processing_message, ^queue_name, message} ->
            assert message == "TestMessageControllerRate_#{i}"
        end
      end

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 10)
      MessageHandler.stop_listen_to_message_processes(self())
    end

    test "Controller sends an overloaded valid message and gets a 200 text reponse", %{conn: conn} do
      MessageHandler.start_listen_to_message_processes(self())
      queue_name = Kernel.inspect(make_ref())
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => queue_name,
                                                   :message => "TestMessageControllerOverload",
                                                   :overload_param => "TestOverloadParam"}))
        |> text_response(200)

      assert response == "Queue #{queue_name} Message TestMessageControllerOverload"
      receive do
        {:processing_message, ^queue_name, message} ->
          assert message == "TestMessageControllerOverload"
      end
    end

    test "Controller is sent invalid messages and gets a 400 text reponse", %{conn: conn} do
      response =
        conn
        |> get(Routes.message_path(conn, :index))
        |> text_response(400)

      assert response == "Wrong Parameters!"

      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => "TestControllerQueue"}))
        |> text_response(400)

      assert response == "Wrong Parameters!"

      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:message => "TestMessageController"}))
        |> text_response(400)

      assert response == "Wrong Parameters!"
    end

  end

end

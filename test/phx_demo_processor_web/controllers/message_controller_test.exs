defmodule PhxDemoProcessorWeb.MessageControllerTest do
  use PhxDemoProcessorWeb.ConnCase
  import PhxDemoProcessor.MonitorProcessHelper, only: [monitor_processing: 1]

  describe "index/2" do
    test "Controller sends a single valid message and gets a 200 text reponse", %{conn: conn} do
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => "TestControllerQueue",
                                                   :message => "TestMessageController"}))
        |> text_response(200)

      assert response == "Queue TestControllerQueue Message TestMessageController"
    end

    test "Controller sends multiple valid messages, gets a 200 text reponse, processes rate limited", %{conn: conn} do
      range = 1..5
      monitor_ref = spawn(fn -> monitor_processing(%{"TestControllerQueueRate" => Enum.count(range)}) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process trace
      for i <- range do
        response =
          conn
          |> get(Routes.message_path(conn, :index, %{:queue => "TestControllerQueueRate",
                                                     :message => "TestMessageControllerRate_#{i}"}))
          |> text_response(200)
        assert response == "Queue TestControllerQueueRate Message TestMessageControllerRate_#{i}"
      end

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 6000)
    end

    test "Controller sends an overloaded valid message and gets a 200 text reponse", %{conn: conn} do
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => "TestControllerQueue",
                                                   :message => "TestMessageControllerOverload",
                                                   :overload_param => "TestOverloadParam"}))
        |> text_response(200)

      assert response == "Queue TestControllerQueue Message TestMessageControllerOverload"
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

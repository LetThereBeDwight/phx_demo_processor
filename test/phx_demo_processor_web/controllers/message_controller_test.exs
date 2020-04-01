defmodule PhxDemoProcessorWeb.MessageControllerTest do
  use PhxDemoProcessorWeb.ConnCase
  import PhxDemoProcessor.MonitorProcessHelper, only: [monitor_queue_processing: 2]

  describe "index/2" do
    test "Controller sends a single valid message and gets a 200 text reponse", %{conn: conn} do
      queue_name = Kernel.inspect(make_ref())
      message = Kernel.inspect(make_ref())
      monitor_ref = spawn_link(fn -> monitor_queue_processing(queue_name, [message]) end)
                    |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process link
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => queue_name,
                                                   :message => message}))
        |> text_response(200)

      assert response == "Queue #{queue_name} Message #{message}"
      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 10)
    end

    test "Controller sends multiple valid messages, gets a 200 text reponse, processes rate limited", %{conn: conn} do
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
        response =
          conn
          |> get(Routes.message_path(conn, :index, %{:queue => queue_name,
                                                     :message => message}))
          |> text_response(200)

        assert response == "Queue #{queue_name} Message #{message}"
      end)

      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 4010)
    end

    test "Controller sends an overloaded valid message and gets a 200 text reponse", %{conn: conn} do
      queue_name = Kernel.inspect(make_ref())
      message = Kernel.inspect(make_ref())
      monitor_ref = spawn_link(fn -> monitor_queue_processing(queue_name, [message]) end)
      |> Process.monitor()

      Process.sleep(100) # Give us some time to start the process link
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => queue_name,
                                                   :message => message,
                                                   :overload_param => "TestOverloadParam"}))
        |> text_response(200)

      assert response == "Queue #{queue_name} Message #{message}"
      assert_receive({:DOWN, ^monitor_ref, _, _, _}, 10)
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

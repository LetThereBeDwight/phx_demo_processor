defmodule PhxDemoProcessorWeb.MessageControllerTest do
  use PhxDemoProcessorWeb.ConnCase

  describe "index/2" do
    test "Controller sends a valid message and gets a 200 text reponse", %{conn: conn} do
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => "TestControllerQueue",
                                                   :message => "TestMessageController"}))
        |> text_response(200)

      assert response == "Queue TestControllerQueue Message TestMessageController"
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

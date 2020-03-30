defmodule PhxDemoProcessorWeb.MessageControllerTest do
  use PhxDemoProcessorWeb.ConnCase

  describe "index/2" do
    test "Controller sends a message and gets a 200 text reponse", %{conn: conn} do
      response =
        conn
        |> get(Routes.message_path(conn, :index, %{:queue => "TestQueue",
                                                   :message => "TestMessage"}))
        |> text_response(200)

      assert response == "Queue TestQueue Message TestMessage"
    end
  end

end

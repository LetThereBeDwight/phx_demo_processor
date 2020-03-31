
defmodule PhxDemoProcessorWeb.MessageController do
  use PhxDemoProcessorWeb, :controller
  alias PhxDemoProcessor.MessageHandler

  def index(conn, %{"queue" => queue, "message" => message}) do
    case MessageHandler.receive_message(queue, message) do
      :ok ->
        text(conn, "Queue #{queue} Message #{message}")
      error ->
        conn
        |> put_status(400)
        |> text("Genersever API Error! #{inspect(error)}")
    end

  end

  def index(conn, _params) do
    #FIXME: Better error handling
    conn
    |> put_status(400)
    |> text("Wrong Parameters!")
  end

end

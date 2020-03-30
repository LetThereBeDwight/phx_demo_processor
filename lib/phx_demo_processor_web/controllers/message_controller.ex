
defmodule PhxDemoProcessorWeb.MessageController do
  use PhxDemoProcessorWeb, :controller
  alias PhxDemoProcessor.MessageHandler

  def index(conn, %{"queue" => queue, "message" => message}) do
    spawn(fn ->
      MessageHandler.receive_message(queue, message)
    end)

    text(conn, "Queue #{queue} Message #{message}")
  end

  def index(conn, _params) do
    #FIXME: This should error out
    text(conn, "Hello World")
  end

end

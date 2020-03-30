
defmodule PhxDemoProcessorWeb.MessageController do
  use PhxDemoProcessorWeb, :controller

  def index(conn, %{"queue" => queue, "message" => message}) do
    text(conn, "Queue #{queue} Message #{message}")
  end

  def index(conn, params) do
    #FIXME: This should error out
    text(conn, "Hello World")
  end

end

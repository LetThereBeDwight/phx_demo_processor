defmodule PhxDemoProcessorWeb.Router do
  use PhxDemoProcessorWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PhxDemoProcessorWeb do
    pipe_through :api
  end
end

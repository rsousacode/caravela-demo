defmodule CaravelaDemoWeb.Router do
  use CaravelaDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CaravelaDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", CaravelaDemoWeb do
    pipe_through :browser

    live "/", CommandCenterLive, :index
  end
end

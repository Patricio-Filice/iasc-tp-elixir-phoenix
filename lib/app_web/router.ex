defmodule AppWeb.Router do
  use AppWeb, :router

  pipeline :browser do
    plug CORSPlug
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AppWeb.LayoutView, :root}
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug CORSPlug
    plug :accepts, ["json"]
  end

  scope "/", AppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/lists", AppWeb do
    pipe_through :browser

    post "/", ListController, :create
    get "/:name", ListController, :get
    get "/", ListController, :list
  end

  scope "/lists/:list_name/tasks", AppWeb do
    pipe_through :browser

    post "/", TaskController, :create
    get "/", TaskController, :list
    delete "/:task_id", TaskController, :remove
    put "/:task_id", TaskController, :update
    post "/:task_id/mark", TaskController, :mark
    delete "/:task_id/mark", TaskController, :unmark
  end

  scope "/lists/:start_list/swaps/tasks", AppWeb do
    pipe_through :browser

    put "/", SwapController, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AppWeb.Telemetry
    end
  end
end

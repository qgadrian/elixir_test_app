defmodule TestApp.Router do
  use TestApp.Web, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  pipeline :api do
    plug :accepts, ["json"]
#    plug Guardian.Plug.VerifyHeader # Looks for token in authorization header
#    plug Guardian.Plug.LoadResource # Makes the current resource available Guardian.Plug.current_resource(conn)
    plug Coherence.Authentication.Session
  end

  scope "/" do
    pipe_through :browser
    coherence_routes
  end

  scope "/" do
    pipe_through :protected
    coherence_routes :protected
  end

  scope "/", TestApp do
    pipe_through :browser # Use the default browser stack
    coherence_routes

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", TestApp do
  #   pipe_through :api
  # end

  scope "/api", TestApp do
    pipe_through :api
    coherence_routes

    scope "/v1" do
      resources "/user", UsersController, only: [:create, :show, :delete, :update]

      resources "/sessions", SessionController, only: [:create, :delete]
    end
  end

end

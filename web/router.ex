defmodule TestApp.Router do
  use TestApp.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug Guardian.Plug.VerifyHeader, realm: "TestApp" # Looks for 'TestApp <jwt>' token in authorization header
    plug Guardian.Plug.LoadResource # Makes the current resource available Guardian.Plug.current_resource(conn)
  end

  scope "/", TestApp do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", TestApp do
  #   pipe_through :api
  # end

  scope "/api", TestApp do
    pipe_through :api

    scope "/v1" do
      resources "/user", UsersController, only: [:create, :show, :delete, :update]

      resources "/sessions", SessionController, only: [:create, :delete]
    end
  end

end

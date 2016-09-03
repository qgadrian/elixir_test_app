defmodule TestApp.SessionController do
  use TestApp.Web, :controller
  use Guardian.Phoenix.Controller

  require Logger

  import Canary.Plugs

  alias TestApp.{Session, SeasonView}

  plug Guardian.Plug.EnsureAuthenticated, [handler: TestApp.SessionController] when action in [:delete]
  plug TestApp.Plug.CanaryUser
  plug :authorize_resource, model: TestApp.User, only: [:delete], unauthorized_handler: {TestApp.SessionHandler, :handle_unauthorized}

  plug :scrub_params, "session" when action in [:create] # Checks the presence of the param 'session'
  # If the required_key is not present, it will raise Phoenix.MissingParamError.
  # https://hexdocs.pm/phoenix/Phoenix.Controller.html#scrub_params/2

  def create(conn, %{"session" => session_params}, current_user, claims) do
    case Session.authenticate(session_params) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = user |> Guardian.encode_and_sign(:token)
          conn
          |> put_status(:created)
          |> render(TestApp.SessionView, "show.json", jwt: jwt)
      :error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json")
    end
  end

  def delete(conn, %{"id" => id}, current_user, {:ok, claims}) do
    jwt = Guardian.Plug.current_token(conn)
    case Guardian.revoke! jwt, claims do
      :ok ->
        render(conn, TestApp.SessionView, "delete.json")
      { :error, :could_not_revoke_token } ->
        SessionHandler.handle_unexpected_error(conn, "Error revoking token")
      { :error, reason } ->
        Logger.debug "Unexpect error removing token: #{reason}"
        SessionHandler.handle_unexpected_error(conn, "Error revoking token")
    end
  end

  def unauthenticated(conn, params) do
    Logger.debug "Not authenticated request. Params: #{inspect(params)}"

    conn
    |> put_status(:forbidden)
    |> render(TestApp.SessionView, "forbidden.json", error: "Not Authenticated")
  end

end
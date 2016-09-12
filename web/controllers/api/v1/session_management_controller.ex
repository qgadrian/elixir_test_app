defmodule TestApp.SessionController do
  use TestApp.Web, :controller
  use Guardian.Phoenix.Controller

  require Logger
  require IEx

  import Canary.Plugs

  alias TestApp.{Session, SeasonView, SessionHelper}

  plug Guardian.Plug.EnsureAuthenticated, [handler: TestApp.SessionHelper] when action in [:delete]
  plug TestApp.Plug.CanaryUser
  plug :authorize_resource, model: TestApp.User, only: [:delete], unauthorized_handler: {TestApp.SessionHelper, :handle_unauthorized}

  plug :scrub_params, "session" when action in [:create] # Checks the presence of the param 'session'
  # If the required_key is not present, it will raise Phoenix.MissingParamError.
  # https://hexdocs.pm/phoenix/Phoenix.Controller.html#scrub_params/2

  def create(conn, %{"session" => session_params}, current_user, claims) do
    case SessionHelper.authenticate(session_params) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = user |> Guardian.encode_and_sign(:token, perms: %{user: [:read, :write]})
          conn
          |> put_status(:ok)
          |> render(TestApp.SessionView, "show.json", jwt: jwt)
      :error ->
        SessionHelper.handle_unauthorized(conn)
    end
  end

  def delete(conn, %{"id" => id}, current_user, {:ok, claims}) do
    jwt = Guardian.Plug.current_token(conn)
    case Guardian.revoke! jwt, claims do
      :ok ->
        conn
        |> put_status(:ok)
        |> render(TestApp.SessionView, "delete.json")
      {:error, :could_not_revoke_token } ->
        SessionHelper.handle_unexpected_error(conn, "Error revoking token")
      {:error, reason } ->
        Logger.debug "Unexpect error removing token: #{reason}"
        SessionHelper.handle_unexpected_error(conn, "Error revoking token")
    end
  end

end

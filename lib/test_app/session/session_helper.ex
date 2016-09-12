defmodule TestApp.SessionHelper do
  require Logger
  require IEx

  alias TestApp.{Repo, User}

  def authenticate(%{"email" => email, "password" => password}) do
    user = Repo.get_by(User, email: String.downcase(email))

    Logger.debug "Authenticating user #{email}"

    case check_password(user, password) do
      true ->
        Logger.debug "Login successful for user #{user.email}"
        {:ok, user}
      _ ->
        Logger.debug "Login failed for user #{email}"
        :error
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> Comeonin.Bcrypt.dummy_checkpw()
      _ -> Comeonin.Bcrypt.checkpw(password, user.encrypted_password)
    end
  end

  # Authetication handlers
  def handle_unexpected_error(conn, error_message) do
    Logger.error ("Unexpected error: #{error_message}")
    conn
    |> Plug.Conn.put_status(:internal_server_error)
    |> Phoenix.Controller.render(TestApp.SessionView, "error.json", error: "Error procesing request")
  end

  def unauthorized(conn, _) do
    handle_unauthorized(conn)
  end

  def handle_unauthorized(conn) do
    Logger.debug "Unauthorized request"
    conn
    |> Plug.Conn.put_status(:forbidden)
    |> Phoenix.Controller.render(TestApp.SessionView, "forbidden.json", error: "Forbidden")
  end

  def unauthenticated(conn, params) do
    Logger.debug "Not authenticated request. Params: #{inspect(params)}"

    conn
    |> Plug.Conn.put_status(:forbidden)
    |> Phoenix.Controller.render(TestApp.SessionView, "forbidden.json", error: "Not Authenticated")
  end

end

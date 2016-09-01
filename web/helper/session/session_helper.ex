defmodule TestApp.Session do
  require Logger

  alias TestApp.{Repo, User}

  def check_user_action_permission(current_user, user_id) do
    case current_user do
      nil -> {:error, :unauthorized}
      _ ->
        if current_user.id == String.to_integer(user_id) do
          {:ok, current_user}
        else
          {:error, :unauthorized}
        end
    end
  end

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

  def handle_unauthorized_request(conn) do
    Logger.debug "Unauthorized request"
    conn
    |> Plug.Conn.put_status(:forbidden)
    |> Phoenix.Controller.render(TestApp.SessionView, "forbidden.json", error: "Forbidden")
  end

  def handle_unexpected_error(conn, error_message) do
    Logger.error ("Unexpected error: #{error_message}")
    conn
    |> Plug.Conn.put_status(:internal_server_error)
    |> Phoenix.Controller.render(TestApp.SessionView, "error.json", error: "Error procesing request")
  end

  defp check_password(user, password) do
    case user do
      nil -> Comeonin.Bcrypt.dummy_checkpw()
      _ -> Comeonin.Bcrypt.checkpw(password, user.encrypted_password)
    end
  end

end
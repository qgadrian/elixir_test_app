defmodule TestApp.Session do
  use TestApp.Web
  alias TestApp.{Repo, User}
  require Logger

  def check_user_action_permission(current_user, id) do
    if current_user.id == String.to_integer(id) do
      {:ok, current_user}
    else
      {:error, :unauthorized}
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
          |> put_status(:forbidden)
          |> render(TestApp.SessionView, "forbidden.json", error: "Forbidden")
        end

  defp check_password(user, password) do
    case user do
      nil -> Comeonin.Bcrypt.dummy_checkpw()
      _ -> Comeonin.Bcrypt.checkpw(password, user.encrypted_password)
    end
  end

end
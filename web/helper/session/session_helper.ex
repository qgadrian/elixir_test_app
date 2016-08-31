defmodule TestApp.Session do
  alias TestApp.{Repo, User}
  require Logger

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
end
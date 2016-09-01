defmodule TestApp.UsersController do
  use TestApp.Web, :controller
  use Guardian.Phoenix.Controller

  require Logger

  alias TestApp.{Repo, User, Session}

  plug Guardian.Plug.EnsureAuthenticated, [handler: TestApp.SessionController] when action in [:update, :delete, :show]

  plug :scrub_params, "user" when action in [:create, :update]
  plug :scrub_params, "id" when action in [:show, :delete]

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(:created)
        |> render(TestApp.SessionView, "show.json", jwt: jwt, user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TestApp.SessionView, "error.json", changeset: changeset)
    end
  end

      def update(conn, %{"user" => user_params}, current_user, claims) do
        id = conn.params["id"]
        case Session.check_user_action_permission(current_user, id) do
              {:ok, user} ->
                Logger.debug "Updating user #{inspect(user)}..."

                changeset = User.changeset(user, user_params)

                case Repo.update(changeset) do
                  {:ok, user} ->
                    Logger.debug "Updated user #{inspect(user)}"
                    conn
                    |> put_status(:ok)
                    |> render(TestApp.SessionView, "show.json", user: user)
                  {:error, changeset} ->
                    Logger.debug "Error updating #{inspect(changeset)}"
                end
              {:error, :unauthorized} ->
                Session.handle_unauthorized_request(conn)
            end
      end

  def show(conn, %{"id" => id}, current_user, claims) do
    case Session.check_user_action_permission(current_user, id) do
      {:ok, user} ->
        conn
        |> put_status(:ok)
        |> render(TestApp.SessionView, "show.json", user: user)
      {:error, :unauthorized} ->
        Session.handle_unauthorized_request(conn)
    end
  end

  def delete(conn, %{"id" => id}, current_user, claims) do
    case Session.check_user_action_permission(current_user, id) do
      {:ok, user} ->
        Logger.debug "Deleting user #{id}..."
        case Repo.delete(user) do
          {:ok, user} ->
            Logger.debug "Deleted user #{id}"
            conn
            |> put_status(:ok)
            |> render(TestApp.SessionView, "delete.json")
          {:error, changeset} ->
            Logger.debug "Error deleting #{id}"
        end
      {:error, :unauthorized} ->
        Session.handle_unauthorized_request(conn)
    end
  end

end
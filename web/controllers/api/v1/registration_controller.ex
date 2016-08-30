defmodule TestApp.UsersController do
  use TestApp.Web, :controller
  require Logger
  alias TestApp.{Repo, User}

#  plug Coherence.Authentication.Session, protected: true when action != :create

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

      def update(conn, %{"user" => user_params}) do
        id = conn.params["id"]
        Logger.debug "id #{id}"
        Logger.debug "user #{inspect(user_params)}"
        case find_user_or_render_not_found(conn, id) do
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
            end
      end

  def show(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)
    Logger.debug "Current user is #{inspect(current_user)}"

    case find_user_or_render_not_found(conn, id) do
      {:ok, user} ->
        Logger.debug "user email is #{user.email} and id is #{user.id}"
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)
            conn
            |> put_status(:ok)
            |> render(TestApp.SessionView, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    Logger.debug "Current logged user is #{inspect(user)}"
    id = -1

    case find_user_or_render_not_found(conn, id) do
      {:ok, user} ->
        Logger.debug "Deleting user #{inspect(user)}..."
        case Repo.delete(user) do
          {:ok, user} ->
            Logger.debug "Deleted user #{inspect(user)}"
            conn
            |> put_status(:ok)
            |> render(TestApp.SessionView, "delete.json")
          {:error, changeset} ->
            Logger.debug "Error deleting #{inspect(changeset)}"
        end
    end
  end

    defp find_user_or_render_not_found(conn, id) do
      case User.find_user_by_id(id) do
        {:ok, user} ->
          {:ok, user}
        {:error, id} ->
          handle_user_not_found(conn, id)
      end
    end

  defp handle_user_not_found(conn, id) do
    Logger.debug "User id not found #{id}"
    conn
    |> put_status(:not_found)
    |> render(TestApp.SessionView, "not_found.json", id: id)
  end
end
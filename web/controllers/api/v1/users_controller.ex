defmodule TestApp.UsersController do
  use TestApp.Web, :controller
  use Guardian.Phoenix.Controller

  require Logger
  require IEx

  import Canary.Plugs

  alias TestApp.{Repo, User, SessionHandler}

  plug Guardian.Plug.EnsureAuthenticated, [handler: TestApp.SessionController] when action in [:update, :delete, :show]
  plug Guardian.Plug.EnsurePermissions, [handler: TestApp.SessionHandler, one_of: [%{user: [:read]}, %{admin: []}]] when action in [:show]
  plug TestApp.Plug.CanaryUser
  plug :authorize_resource, model: TestApp.User, only: [:update, :delete, :show], unauthorized_handler: {TestApp.SessionHandler, :handle_unauthorized}

  plug :scrub_params, "user" when action in [:create, :update]
  plug :scrub_params, "id" when action in [:show, :delete]

  def create(conn, %{"user" => user_params}, current_user, _) do
    changeset = User.create_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(:created)
        |> render(TestApp.SessionView, "show.json", jwt: jwt, user: user)

      {:error, changeset} ->
        handle_user_creation_validation_error(conn, changeset: changeset)
    end
  end

  def update(conn, %{"user" => user_params}, current_user, claims) do
    Logger.debug "Updating user #{inspect(current_user)}..."
    changeset = User.update_changeset(current_user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        Logger.debug "Updated user #{inspect(user)}"
        conn
        |> put_status(:ok)
        |> render(TestApp.SessionView, "show.json", user: user)
      {:error, changeset} ->
        SessionHandler.handle_unexpected_error(conn, "Error updating #{inspect(changeset)}")
    end
  end

  def show(conn, %{"id" => id}, current_user, {:ok, claims}) do
    request_resource = conn.assigns[:request_resource]
    case request_resource do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(TestApp.SessionView, "not_found.json", id: id)
      _ ->
        conn
        |> put_status(:ok)
        |> render(TestApp.SessionView, "show.json", user: conn.assigns[:request_resource])
    end
  end

  def delete(conn, %{"id" => id}, current_user, claims) do
    Logger.debug "Deleting user #{id}..."
    case Repo.delete(current_user) do
      {:ok, user} ->
        Logger.debug "Deleted user #{id}"
          conn
          |> Guardian.Plug.sign_out(:secret)
          |> put_status(:ok)
          |> render(TestApp.SessionView, "delete.json")
      {:error, _} ->
        Logger.debug "Error deleting #{id}"
    end
  end

  defp handle_user_creation_validation_error(conn, changeset: changeset) do
    Logger.debug "User creation error #{inspect(changeset.errors)}"
    case changeset do
      %Ecto.Changeset{valid?: false} ->
      validation_errors = TestApp.ChangesetView.render_errors(changeset: changeset)
      conn
      |> put_status(:conflict)
      |> render(TestApp.SessionView, "error.json", errors: validation_errors)
    end
  end

end

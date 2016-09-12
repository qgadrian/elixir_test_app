defmodule TestApp.UsersController do
  use TestApp.Web, :controller
  use Guardian.Phoenix.Controller

  require Logger
  require IEx

  import Canary.Plugs

  alias TestApp.{Repo, User, Role, SessionHelper}

  plug Guardian.Plug.EnsureAuthenticated, [handler: TestApp.SessionHelper] when action in [:update, :delete, :show]
  plug Guardian.Plug.EnsurePermissions, [handler: TestApp.SessionHelper, one_of: [%{user: [:read]}, %{admin: []}]] when action in [:show]
  plug TestApp.Plug.CanaryUser
  plug :load_and_authorize_resource, model: TestApp.User, only: [:update, :delete, :show], unauthorized_handler: {TestApp.SessionHelper, :handle_unauthorized}

  plug :scrub_params, "user" when action in [:create, :update]
  plug :scrub_params, "id" when action in [:show, :delete]

  def create(conn, %{"user" => user_params}, _, _) do
    changeset = User.create_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token, perms: %{user: [:read, :write]})
        conn
        |> put_status(:ok)
        |> render(TestApp.SessionView, "show.json", jwt: jwt, user: user)

      {:error, changeset} ->
        handle_user_creation_validation_error(conn, changeset: changeset)
    end
  end

  def update(conn, %{"user" => user_params}, current_user, claims) do
    changeset = User.update_changeset(current_user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:ok)
        |> render(TestApp.SessionView, "show.json", user: user)
      {:error, changeset} ->
        handle_user_creation_validation_error(conn, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, _, {:ok, claims}) do
    requested_user = conn.assigns[:user]

    case conn.assigns.authorized do
      false -> conn
      true ->
        case requested_user do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(TestApp.SessionView, "not_found.json", id: id)
          requested_user ->
            conn
            |> put_status(:ok)
            |> render(TestApp.SessionView, "show.json", user: requested_user)
        end
    end
  end

  def delete(conn, %{"id" => id}, _, claims) do

    try do
      requested_user = get_request_user(conn)

      case Repo.delete(requested_user) do
        {:ok, user} ->
          conn
          |> Guardian.Plug.sign_out(:secret)
          |> put_status(:ok)
          |> render(TestApp.SessionView, "delete.json")
        {:error, _} ->
          SessionHelper.handle_unexpected_error(conn, "Error deleting user with id #{id}")
      end
    rescue
      NotRequestUserFound -> handle_no_request_user_found(conn, id)
    end
  end

  defp get_request_user(conn) do
    case conn.assigns.authorized do
      false -> raise NotRequestUserFound
      true -> conn.assigns[:user]
    end
  end

  defp handle_no_request_user_found(conn, id) do
    if (conn.state != :sent) do
      conn
      |> put_status(:not_found)
      |> render(TestApp.SessionView, "not_found.json", id: id)
    else
      conn
    end
  end

  defp handle_user_creation_validation_error(conn, changeset: changeset) do
    Logger.debug "User creation error #{inspect(changeset.errors)}"
    validation_errors = TestApp.ChangesetView.render_errors(changeset: changeset)
    conn
    |> put_status(:conflict)
    |> render(TestApp.SessionView, "error.json", errors: validation_errors)
  end

end

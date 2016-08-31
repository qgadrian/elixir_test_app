defmodule TestApp.SessionController do
  use TestApp.Web, :controller
  require Logger

   plug Guardian.Plug.EnsureAuthenticated, [handler: TestApp.SessionController] when action in [:delete]

  plug :scrub_params, "session" when action in [:create] # Checks the presence of the param 'session'
  # If the required_key is not present, it will raise Phoenix.MissingParamError.
  # https://hexdocs.pm/phoenix/Phoenix.Controller.html#scrub_params/2

  def create(conn, %{"session" => session_params}) do
    case TestApp.Session.authenticate(session_params) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = user |> Guardian.encode_and_sign(:token)
          conn
          |> put_status(:created)
          |> Guardian.Plug.sign_in(user)
          |> render(TestApp.SessionView, "show.json", jwt: jwt, user: user)
      :error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json")
    end
  end

  def delete(conn, _) do
    conn
    |> Guardian.Plug.sign_out
    |> render(TestApp.SessionView, "delete.json")
  end

  def unauthenticated(conn, params) do
    Logger.debug "Not authenticated request. Params: #{inspect(params)}"

    conn
    |> put_status(:forbidden)
    |> render(TestApp.SessionView, "forbidden.json", error: "Not Authenticated")
  end
end
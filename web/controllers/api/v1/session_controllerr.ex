defmodule TestApp.SessionController do
  use TestApp.Web, :controller

  plug :scrub_params, "session" when action in [:create] # Checks the presence of the param 'session'
  # If the required_key is not present, it will raise Phoenix.MissingParamError.
  # https://hexdocs.pm/phoenix/Phoenix.Controller.html#scrub_params/2

  def create(conn, %{"session" => session_params}) do
    case TestApp.Session.authenticate(session_params) do
      {:ok, user} ->
#        {:ok, jwt, _full_claims} = user |> Guardian.encode_and_sign(:token)

        conn
        |> put_status(:created)
        |> fetch_session
        |> Guardian.Plug.sign_in(user)
        |> render(TestApp.SessionView, "show.json", user: user)
#        |> render("show.json", jwt: jwt, user: user)

      :error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json")
    end
  end

  def delete(conn, _) do
    {:ok, claims} = Guardian.Plug.claims(conn)

    conn
    |> Guardian.Plug.current_token
    |> Guardian.revoke!(claims)

    conn
    |> render("delete.json")
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> render(TestApp.SessionView, "forbidden.json", error: "Not Authenticated")
  end
end
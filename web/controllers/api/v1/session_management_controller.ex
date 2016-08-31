defmodule TestApp.SessionController do
  use TestApp.Web, :controller
  require Logger

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

#        conn = conn |> fetch_session |> put_session(:request_token, user)
#        Guardian.Plug.sign_in(conn, user)
#        text conn, ""

#        new_conn = Guardian.Plug.api_sign_in(conn, user)
#        Logger.debug "Conn #{inspect(new_conn)}"
#        jwt = Guardian.Plug.current_token(new_conn)
#        Logger.debug "Jwt #{inspect(jwt)}"
#        claims = Guardian.Plug.claims(new_conn)
#        Logger.debug "Claims #{inspect(claims)}"
#        case claims do
#          {:ok, _claims} ->
#            exp = Map.get(_claims, "exp")
#            Logger.debug "Exp #{inspect(exp)}"
#
#            new_conn
##            |> put_resp_header("authorization", "TestApp #{jwt}")
##            |> put_resp_header("x-expires", exp)
#            |> render(TestApp.SessionView, "show.json", user: user, jwt: jwt, exp: exp)
#        end
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
    Logger.debug "Not authenticated request. Params: #{inspect(_params)}"

    conn
    |> put_status(:forbidden)
    |> render(TestApp.SessionView, "forbidden.json", error: "Not Authenticated")
  end
end
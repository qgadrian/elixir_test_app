defmodule TestApp.SessionControllerTest do
  use TestApp.ConnCase, async: false

  alias TestApp.{User}

  require Logger
  require IEx

  defp doLogin(email, password) do
    conn = build_conn
    response = post conn, "/api/v1/sessions", %{session: %{email: email, "password": password}}
    json_response(response, 200)["jwt"]
  end

  test "Login and get session token", %{conn: conn} do
    response = post conn, "/api/v1/sessions", %{session: %{email: "5@email.com", "password": "verylongpassword"}}
    assert json_response(response, 200)["jwt"] != nil
  end

  test "Logout and check invalid session token", %{conn: conn} do
    user_id = 5

    user = User.find_by_email("#{user_id}@email.com")

    jwt = doLogin(user.email, "verylongpassword")
    jwt = "TestApp #{jwt}"

    # Check valid token
    conn = conn
    |> put_req_header("authorization", jwt)
    |> get("/api/v1/user/#{user_id}")

    assert json_response(conn, 200)

    # Logout
    conn = build_conn
    |> put_req_header("authorization", jwt)
    |> delete("/api/v1/sessions/#{user_id}")

    assert json_response(conn, 200)

    # Check invalid token
    conn = build_conn
    |> put_req_header("authorization", jwt)
    |> get("/api/v1/user/#{user_id}")

    assert json_response(conn, 403)
  end

end

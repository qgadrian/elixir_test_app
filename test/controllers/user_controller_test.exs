defmodule TestApp.UserControllerTest do
  use TestApp.ConnCase, async: false

  alias TestApp.{User, UserTestHelper}

  require Logger
  require IEx

  @user_1_attrs %{user: %{email: "some@email.com", password: "verylongpassword", password_confirmation: "verylongpassword", first_name: "some content", last_name: "some content"}}
  @user_2_attrs %{user: %{email: "some2@email.com", password: "verylongpassword", password_confirmation: "verylongpassword", first_name: "some content", last_name: "some content"}}

  defp doLogin(email, password) do
    conn = build_conn()
    response = post conn, "/api/v1/sessions", %{session: %{email: email, "password": password}}
    json_response(response, 200)["jwt"]
  end

  # Create
  test "Create a new user", %{conn: conn} do
    conn = conn
    |> post("/api/v1/user", @user_1_attrs)

    UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, @user_1_attrs)
  end

  # Show
  test "Return own user info", %{conn: conn} do
    user_id = 5

    user = User.find_by_email("#{user_id}@email.com")

    jwt = doLogin(user.email, "verylongpassword") |> UserTestHelper.buildJwtToken

    conn = conn
    |> put_req_header("authorization", jwt)
    |> get("/api/v1/user/#{user_id}")

    response = assert json_response(conn, 200)["user"]

    user_params =
      %{}
      |> Map.put_new("email", user.email)
      |> Map.put_new("first_name", user.first_name)
      |> Map.put_new("last_name", user.last_name)

    expected_params = Map.take(response, ["email", "first_name", "last_name"])

    assert user_params == expected_params
  end

  test "Show an user using and id that belongs to the session token", %{conn: conn} do
    # Create user
    conn = conn
    |> post("/api/v1/user", @user_1_attrs)

    response = UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, @user_1_attrs)

    # Request user
    user_id = response["user"]["id"]
    jwt = UserTestHelper.buildJwtToken(response["jwt"])

    conn = build_conn()
    |> put_req_header("authorization", jwt)
    |> get("/api/v1/user/#{user_id}")

    UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, @user_1_attrs)
  end

  test "Show request forbidden because requesting an id with a session token that belongs to another id", %{conn: conn} do
    # Create user
    conn = conn
    |> post("/api/v1/user", @user_1_attrs)

    response = UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, @user_1_attrs)
    first_user_jwt = UserTestHelper.buildJwtToken(response["jwt"])

    # Create the second user
    conn = build_conn()
    |> post("/api/v1/user", @user_2_attrs)

    second_response = UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, @user_2_attrs)
    user_id = second_response["user"]["id"]

    # Request user
    conn = build_conn()
    |> put_req_header("authorization", first_user_jwt)
    |> get("/api/v1/user/#{user_id}")

    assert json_response(conn, 403)
  end

  # Update
  test "Update all fields of an user", %{conn: conn} do
    updated_user_params = %{user: %{email: "edited@email.com", password: "verylongeditedpassword", password_confirmation: "verylongeditedpassword", first_name: "some edited content", last_name: "some edited content"}}

    # Create user
    conn = conn
    |> post("/api/v1/user", @user_1_attrs)

    response = UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, @user_1_attrs)
    user_id = response["user"]["id"]

    # Update user
    jwt = UserTestHelper.buildJwtToken(response["jwt"])

    conn = build_conn()
    |> put_req_header("authorization", jwt)
    |> patch("/api/v1/user/#{user_id}", updated_user_params)

    UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, updated_user_params)
  end

  test "Update a user with invalid params responds an error 409", %{conn: conn} do
    invalid_email_param = %{user: %{email: "edited"}}
    invalid_password_param = %{user: %{password: "verylongeditedpassword", password_confirmation: "a"}}
    invalid_password_empty_param = %{user: %{password: "", password_confirmation: ""}}

    # Create user
    conn = conn
    |> post("/api/v1/user", @user_1_attrs)

    response = UserTestHelper.assertResponseOkUserParamsMatchUserResponse(conn, @user_1_attrs)

    # Failing updates
    user_id = response["user"]["id"]
    jwt = UserTestHelper.buildJwtToken(response["jwt"])

    conn = build_conn()
    |> put_req_header("authorization", jwt)
    |> patch("/api/v1/user/#{user_id}", invalid_email_param)
    assert json_response(conn, 409)

    conn = build_conn()
    |> put_req_header("authorization", jwt)
    |> patch("/api/v1/user/#{user_id}", invalid_password_param)
    assert json_response(conn, 409)

    conn = build_conn()
    |> put_req_header("authorization", jwt)
    |> patch("/api/v1/user/#{user_id}", invalid_password_empty_param)
    assert json_response(conn, 409)
  end

  # Delete
  test "Delete an user", %{conn: conn} do
    response = conn
    |> post("/api/v1/user", @user_1_attrs)
    |> UserTestHelper.assertResponseOkUserParamsMatchUserResponse(@user_1_attrs)
    
    user_id = response["user"]["id"]
    jwt = UserTestHelper.buildJwtToken(response["jwt"])

    conn = build_conn()
    |> put_req_header("authorization", jwt)
    |> delete("/api/v1/user/#{user_id}")
  end

  test "Delete an user with another token not authorized", %{conn: conn} do
    # User 1
    user_1_response =
      conn
      |> post("/api/v1/user", @user_1_attrs)
      |> UserTestHelper.assertResponseOkUserParamsMatchUserResponse(@user_1_attrs)

    user_1_id = user_1_response["user"]["id"]

    # User 2
    user_2_response = build_conn()
      |> post("/api/v1/user", @user_2_attrs)
      |> UserTestHelper.assertResponseOkUserParamsMatchUserResponse(@user_2_attrs)

    user_2_id = user_2_response["user"]["id"]
    user_2_jwt = UserTestHelper.buildJwtToken(user_2_response["jwt"])

    conn = build_conn()
    |> put_req_header("authorization", user_2_jwt)
    |> delete("/api/v1/user/#{user_1_id}")

    assert json_response(conn, 403)
  end

end

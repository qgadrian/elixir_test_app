ExUnit.start
Faker.start

Ecto.Adapters.SQL.Sandbox.mode(TestApp.Repo, :manual)

defmodule TestApp.UserTestHelper do
  use TestApp.ConnCase

  def buildJwtToken(jwt) do
    "TestApp #{jwt}"
  end

  def assertResponseOkUserParamsMatchUserResponse(conn, user_params) do
    response = assert json_response(conn, 200)

    created_user_params = getUserAttributeMapFromUserModel(response)
    expected_params = getUserAttributeMapFromParamsMap(user_params)

    assert expected_params == created_user_params

    response
  end

  def assertBothUserStructs(user_struct, user_struct_2, equal_attrs, distinct_attrs) do
    user_params = getUserAttributeMapFromUserStruct(user_struct)
    user_params_2 = getUserAttributeMapFromUserStruct(user_struct_2)

    Enum.each equal_attrs, fn atrr ->
      structModelCheck(user_struct, user_struct_2, atrr, true)
    end

    Enum.each distinct_attrs, fn atrr ->
      structModelCheck(user_struct, user_struct_2, atrr, false)
    end
  end

  def structModelCheck(user_struct, user_struct_2, attr_key, should_be_equals) do
    user_struct_value = Map.get(user_struct, attr_key)
    user_struct_value_2 = Map.get(user_struct_2, attr_key)

    if should_be_equals do
      assert user_struct_value == user_struct_value_2
    else
      assert user_struct_value != user_struct_value_2
    end
  end

  defp getUserAttributeMapFromUserStruct(user) do
    %{}
    |> Map.put_new("email", user.email)
    |> Map.put_new("first_name", user.first_name)
    |> Map.put_new("last_name", user.last_name)
    |> Map.put_new("encrypted_password", user.encrypted_password)
    |> Map.put_new("password", user.password)
  end

  defp getUserAttributeMapFromParamsMap(user_params) do
      %{}
      |> Map.put_new("email", user_params.user.email)
      |> Map.put_new("first_name", user_params.user.first_name)
      |> Map.put_new("last_name", user_params.user.last_name)
  end

  defp getUserAttributeMapFromUserModel(user) do
    %{}
    |> Map.put_new("email", user["user"]["email"])
    |> Map.put_new("first_name", user["user"]["first_name"])
    |> Map.put_new("last_name", user["user"]["last_name"])
  end

end

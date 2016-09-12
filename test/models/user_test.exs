defmodule TestApp.UserTest do
  use TestApp.ModelCase

  require IEx

  alias TestApp.{User, Repo, UserTestHelper}

  # Valid attributes
  @valid_attrs %{"email" => "some@email.com", "password" => "verylongpassword", "password_confirmation" => "verylongpassword", "first_name" => "some content", "last_name" => "some content"}
  @valid_email_attr %{"email" => "another@email.com"}
  @valid_first_name_attr %{"first_name" => "valid firstname"}
  @valid_last_name_attr %{"last_name" => "valid lastname"}
  @valid_first_and_last_name_attr %{"first_name" => "valid firstname", "last_name" => "valid lastname"}
  @valid_password_attr %{"password" => "someeditedpassword", "password_confirmation" => "someeditedpassword"}

  # Invalid attributes
  @invalid_attrs_email %{"email" => "invalid_email"}
  @invalid_attrs_pass_short %{"password" => "short"}
  @invalid_attrs_pass_mismatch %{"password" => "a_valid_password", "password_confirmation" => "another_one_different"}

  # Create
  test "Create user with valid attributes" do
    changeset = User.create_changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "Create user fail because invalid email attribute" do
    changeset = User.create_changeset(%User{}, Map.merge(@valid_attrs, @invalid_attrs_email))
    refute changeset.valid?
  end

  test "Create user fail because password too short" do
    changeset = User.create_changeset(%User{}, Map.merge(@valid_attrs, @invalid_attrs_pass_short))
    refute changeset.valid?
  end

  test "Create user fail because password and password confirmation are not the same" do
    changeset = User.create_changeset(%User{}, Map.merge(@valid_attrs, @invalid_attrs_pass_mismatch))
    refute changeset.valid?
  end

  # Update
  defp update_user_test(create_params, update_params, attrs_should_be_equal, attrs_should_be_distinct) do
    created_user =
      User.create_changeset(%User{}, create_params)
      |> Repo.insert!

    update_params = Map.merge(create_params, update_params)
    updated_user =
      User.update_changeset(created_user, update_params)
      |> Repo.update!

    UserTestHelper.assertBothUserStructs(created_user, updated_user, attrs_should_be_equal, attrs_should_be_distinct)
  end

  test "Update user first name and last name" do
    attrs_should_be_equal = [:email, :password, :encrypted_password]
    attrs_should_be_distinct = [:first_name, :last_name]
    update_user_test(@valid_attrs, @valid_first_and_last_name_attr, attrs_should_be_equal, attrs_should_be_distinct)
  end

  test "Update user first name" do
    attrs_should_be_equal = [:last_name, :email, :password, :encrypted_password]
    attrs_should_be_distinct = [:first_name]
    update_user_test(@valid_attrs, @valid_first_name_attr, attrs_should_be_equal, attrs_should_be_distinct)
  end

  test "Update user last name" do
    attrs_should_be_equal = [:first_name, :email, :password, :encrypted_password]
    attrs_should_be_distinct = [:last_name]
    update_user_test(@valid_attrs, @valid_last_name_attr, attrs_should_be_equal, attrs_should_be_distinct)
  end

  test "Update user password" do
    attrs_should_be_equal = [:email, :last_name, :first_name, :last_name]
    attrs_should_be_distinct = [:password, :encrypted_password]
    update_user_test(@valid_attrs, @valid_password_attr, attrs_should_be_equal, attrs_should_be_distinct)
  end

  test "Update user email" do
    attrs_should_be_equal = [:first_name, :last_name, :password, :encrypted_password]
    attrs_should_be_distinct = [:email]
    update_user_test(@valid_attrs, @valid_email_attr, attrs_should_be_equal, attrs_should_be_distinct)
  end

  # Delete
  test "Delete an user" do
    created_user = User.create_changeset(%User{}, @valid_attrs)
    |> Repo.insert!

    Repo.get!(User, created_user.id)

    Repo.delete(created_user)

    assert_raise Ecto.NoResultsError, fn ->
      Repo.get!(User, created_user.id)
    end
  end
end

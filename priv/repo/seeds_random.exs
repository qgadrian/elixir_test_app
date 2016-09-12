Faker.start

defmodule TestApp.Populater do
alias TestApp.Repo

require Logger
require IEx

  def user_attrs do
    %{
      first_name: Faker.Name.first_name,
      last_name: Faker.Name.last_name,
      email: Faker.Internet.email,
      password: "verylongpassword",
      password_confirmation: "verylongpassword"
    }
  end

  def insert_user(attrs \\ %{}) do
    params = Dict.merge(user_attrs, attrs)
    Logger.debug "params #{inspect(params)}"
    #|> TestApp.User.create_changeset
    IEx.pry

    # role = Map.from_struct(List.first(TestApp.Role.find_by_name("user")))
    #
    # %TestApp.User{}
    # |> TestApp.User.create_changeset(params)
    # |> Repo.insert!
    # |> Ecto.build_assoc(:role, %{role_id: 1})

    user = TestApp.User.create_changeset(%TestApp.User{}, params)

    TestApp.Role.find_by_name("user")
    |> TestApp.Repo.preload(:users)
    |> Ecto.build_assoc(:users)
    |> Ecto.Changeset.put_assoc(:users, user)
    |> Repo.insert!

  end
end

  config = %{
    users: 23
  }

  for _u <- 1..config[:users] do
    TestApp.Populater.insert_user
  end

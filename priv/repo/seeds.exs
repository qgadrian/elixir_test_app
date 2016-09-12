# Clear DB
# Mix.Task.run("mix ecto.drop && mix ecto.create && mix ecto.migrate")

alias TestApp.{User, Role, Repo}

# Roles
role_admin = TestApp.Repo.insert!(%TestApp.Role{name: "admin"})
role_user = TestApp.Repo.insert!(%TestApp.Role{name: "user"})

# Users

config = %{
  users: 23
}

for index <- 1..config[:users] do
  # %TestApp.User{}
  # |> TestApp.User.create_changeset(%{
  #       first_name: "FirstName#{index}",
  #       last_name: "LastName#{index}",
  #       email: "#{index}@email.com",
  #       password: "verylongpassword",
  #       password_confirmation: "verylongpassword"
  #     })
  # |> Ecto.build_assoc(:role, role_user)
  # |> Repo.insert!

  role_user
  |> Ecto.build_assoc(:users)
  |> User.create_changeset(%{
        first_name: "FirstName#{index}",
        last_name: "LastName#{index}",
        email: "#{index}@email.com",
        password: "verylongpassword",
        password_confirmation: "verylongpassword"
      })
  |> Repo.insert!
end

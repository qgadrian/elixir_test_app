defmodule TestApp.Repo.Migrations.AddRoleIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :role_id, references(:role)
    end

    create index(:user, [:role_id])
  end
end

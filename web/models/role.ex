defmodule TestApp.Role do
  use TestApp.Web, :model

  alias TestApp.{Repo, Role}

  schema "role" do
    field :name, :string

    timestamps()

    has_many :users, TestApp.User
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  # Query methods
  def find_by_name(name) do
    Repo.one! from r in Role,
     where: r.name == ^name,
     select: r
  end
end

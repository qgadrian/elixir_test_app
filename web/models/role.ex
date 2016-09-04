defmodule TestApp.Role do
  use TestApp.Web, :model

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
  end
end

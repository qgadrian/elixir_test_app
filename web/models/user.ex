defmodule TestApp.User do
  use TestApp.Web, :model
  require Logger

  alias TestApp.{Repo, User}

  # Schema definition
  schema "user" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true

    timestamps()
  end

  # Model constraints
  @required_fields ~w(first_name last_name email password)
  @optional_fields ~w(encrypted_password)

  @required_update_fields ~w()
  @optional_update_fields ~w(first_name last_name email password encrypted_password)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def create_changeset(struct, params \\ :empty) do
    changeset(struct, params, @required_fields, @optional_fields)
  end

  def update_changeset(struct, params \\ :empty) do
    changeset(struct, params, @required_update_fields, @optional_update_fields)
  end

  defp changeset(struct, params \\ :empty, required_field, optional_fiels) do
    struct
    |> cast(params, required_field, optional_fiels)
    |> validate_format(:email, ~r/@/, message: "invalid format")
    |> validate_length(:password, min: 5)
    |> validate_confirmation(:password, message: "password does not match")
    |> unique_constraint(:email, message: "email already taken")
    |> generate_encrypted_password
  end

  defp generate_encrypted_password(current_changeset) do
    case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        Logger.debug "Generating encrypted password..."
        put_change(current_changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
      _ ->
        current_changeset
    end
  end

  # Query methods
  def find_user_by_email(email) do
   case Repo.get(User, email) do
     nil -> {:error, email}
     user -> {:ok, user}
   end
  end

   # Json serialization
  defimpl Poison.Encoder, for: TestApp.User do
    def encode(model, opts) do
      model
      |> Map.take([:id, :first_name, :last_name, :email])
      |> Poison.Encoder.encode(opts)
    end
  end

end

defmodule TestApp.User do
  use TestApp.Web, :model

  require Logger

  alias TestApp.{Repo, User, Role}

  # Schema definition
  schema "user" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true

    belongs_to :role, TestApp.Role # embbed stuff cannot be use in requred/optional fields

    timestamps()
  end

  # Model constraints
  @required_fields ~w(first_name last_name email password role_id)
  @optional_fields ~w()

  @required_update_fields ~w(password) # Password always will be a required field to prevent token stolen user updatings
  @optional_update_fields ~w(first_name last_name email)


  def create_changeset(struct, params \\ :empty) do
    role_id = Role.find_by_name("user").id
    user_params = Map.put_new(params, "role_id", role_id)

    changeset(struct, user_params, @required_fields, @optional_fields)
    |> cast_assoc(:role)
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
  def find_by_email(email) do
    Repo.one! from u in User,
     where: u.email == ^email,
     select: u
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

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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ :empty) do
    Logger.debug "User creation with params #{inspect(params)}"
    struct
    |> cast(params, @required_fields, @optional_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 5)
    |> validate_confirmation(:password, message: "Password does not match")
    |> unique_constraint(:email, message: "Email already taken")
    |> generate_encrypted_password
  end

  defp generate_encrypted_password(current_changeset) do
    case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        Logger.debug "Generating encrypted password..."
        put_change(current_changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
      _ ->
        Logger.debug "Not valid user data #{inspect(current_changeset)}"
        current_changeset
    end
  end

  # Query methods
  def find_user_by_id(id) do
   case Repo.get(User, id) do
     nil -> {:error, id}
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

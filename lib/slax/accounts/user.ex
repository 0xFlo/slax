defmodule Slax.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @hash_opts [hash_password: true, validate_email: true]

  schema "users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  A changeset for user registration, including optional password hashing and email uniqueness validation.
  """
  def registration_changeset(user, attrs, opts \\ @hash_opts) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> validate_username()
    |> validate_email(opts)
    |> validate_password(opts)
  end

  @doc """
  A changeset for changing the username, ensuring it is unique.
  """
  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> validate_username()
  end

  @doc """
  A changeset for changing the email, ensuring that the email actually changes.
  """
  def email_changeset(user, attrs, opts \\ @hash_opts) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> validate_change(:email, &email_change_required/2)
  end

  @doc """
  A changeset for changing the password with optional hashing.
  """
  def password_changeset(user, attrs, opts \\ @hash_opts) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms a user's account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    change(user, confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Validates the current password or adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  Verifies if the given password matches the stored hashed password.
  """
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _), do: Bcrypt.no_user_verify() && false

  # Private helpers

  defp validate_username(changeset) do
    changeset
    |> validate_length(:username, min: 3, max: 20)
    |> unsafe_validate_unique(:username, Slax.Repo)
    |> unique_constraint(:username)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp email_change_required(:email, %{changes: %{email: _}}), do: []
  defp email_change_required(:email, _), do: [{:email, "did not change"}]

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Slax.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp maybe_hash_password(changeset, opts) do
    if Keyword.get(opts, :hash_password, true) && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(get_change(changeset, :password)))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
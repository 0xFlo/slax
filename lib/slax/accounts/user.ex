defmodule Slax.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Slax.Repo

  @default_hash_and_validation_options [hash_password: true, validate_email: true]
  @maximum_username_length 20
  @minimum_username_length 3
  @maximum_email_length 160
  @minimum_password_length 12
  @maximum_password_length 72
  @maximum_bio_length 500
  @maximum_location_length 100
  @maximum_website_length 255

  schema "users" do
    field :email, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :current_password, :string, virtual: true, redact: true

    field :username, :string
    field :bio, :string
    field :location, :string
    field :website, :string

    # social profile fields
    field :github_handle, :string
    field :twitter_handle, :string
    field :linkedin_url, :string
    field :mastodon_handle, :string

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attributes, options \\ @default_hash_and_validation_options) do
    user
    |> cast(attributes, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> validate_new_username()
    |> validate_new_email(options)
    |> validate_new_password(options)
  end

  def profile_changeset(user, attributes) do
    user
    |> cast(attributes, [
      :bio,
      :location,
      :website,
      :github_handle,
      :twitter_handle,
      :linkedin_url,
      :mastodon_handle
    ])
    |> validate_length(:bio, max: @maximum_bio_length)
    |> validate_length(:location, max: @maximum_location_length)
    |> validate_length(:website, max: @maximum_website_length)
    |> validate_website_url_format()
    |> remove_whitespace_from_profile_fields()
  end

  def username_changeset(user, attributes) do
    user
    |> cast(attributes, [:username])
    |> validate_required([:username])
    |> validate_new_username()
  end

  def email_changeset(user, attributes, options \\ @default_hash_and_validation_options) do
    user
    |> cast(attributes, [:email])
    |> validate_required([:email])
    |> validate_new_email(options)
    |> validate_change(:email, &email_change_required/2)
  end

  def password_changeset(user, attributes, options \\ @default_hash_and_validation_options) do
    user
    |> cast(attributes, [:password])
    |> validate_required([:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_new_password(options)
  end

  def account_confirmation_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def validate_current_password(changeset, provided_password) do
    if valid_password?(changeset.data, provided_password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def valid_password?(%Slax.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp validate_new_username(changeset) do
    changeset
    |> validate_length(:username, min: @minimum_username_length, max: @maximum_username_length)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]+$/,
      message: "can only contain letters, numbers, underscores, and dashes"
    )
    |> unsafe_validate_unique(:username, Repo)
    |> unique_constraint(:username)
    |> convert_username_to_lowercase()
  end

  defp validate_new_email(changeset, options) do
    changeset
    |> validate_length(:email, max: @maximum_email_length)
    |> validate_email_format()
    |> enforce_email_uniqueness(options)
    |> convert_email_to_lowercase()
  end

  defp validate_new_password(changeset, options) do
    changeset
    |> validate_length(:password, min: @minimum_password_length, max: @maximum_password_length)
    |> validate_password_contains_number()
    |> validate_password_contains_uppercase()
    |> validate_password_contains_special_character()
    |> hash_password_if_valid(options)
  end

  defp validate_website_url_format(changeset) do
    validate_change(changeset, :website, fn :website, website_url ->
      if is_empty_string?(website_url) do
        []
      else
        case URI.parse(website_url) do
          %URI{scheme: scheme, host: host}
          when scheme in ["http", "https"] and not is_nil(host) ->
            []

          _ ->
            [website: "must be a valid HTTP(S) URL"]
        end
      end
    end)
  end

  defp validate_email_format(changeset) do
    changeset
    |> validate_change(:email, fn :email, email ->
      cond do
        String.length(email) > @maximum_email_length ->
          [email: "is too long"]

        String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/) ->
          validate_email_structure(email)

        true ->
          [email: "must be a valid email address"]
      end
    end)
  end

  defp validate_email_structure(email) do
    case String.split(email, "@") do
      [local_part, domain] when byte_size(local_part) <= 64 and byte_size(domain) <= 255 ->
        []

      [local_part, _] when byte_size(local_part) > 64 ->
        [email: "username part is too long"]

      [_, domain] when byte_size(domain) > 255 ->
        [email: "domain part is too long"]

      _ ->
        [email: "must be a valid email address"]
    end
  end

  defp validate_password_contains_number(changeset) do
    validate_format(changeset, :password, ~r/[0-9]/, message: "must include at least one number")
  end

  defp validate_password_contains_uppercase(changeset) do
    validate_format(changeset, :password, ~r/[A-Z]/,
      message: "must include at least one uppercase letter"
    )
  end

  defp validate_password_contains_special_character(changeset) do
    validate_format(changeset, :password, ~r/[!@#$%^&*(),.?":{}|<>]/,
      message: "must include at least one special character"
    )
  end

  defp enforce_email_uniqueness(changeset, options) do
    if Keyword.get(options, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp hash_password_if_valid(changeset, options) do
    if should_hash_password?(changeset, options) do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(get_change(changeset, :password)))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp should_hash_password?(changeset, options) do
    Keyword.get(options, :hash_password, true) && changeset.valid?
  end

  defp email_change_required(:email, %{changes: %{email: _}}), do: []
  defp email_change_required(:email, _), do: [{:email, "did not change"}]

  defp is_empty_string?(nil), do: true
  defp is_empty_string?(""), do: true
  defp is_empty_string?(_), do: false

  defp remove_whitespace_from_profile_fields(changeset) do
    profile_fields = [
      :bio,
      :location,
      :website,
      :github_handle,
      :twitter_handle,
      :linkedin_url,
      :mastodon_handle
    ]

    Enum.reduce(profile_fields, changeset, fn field, current_changeset ->
      if value = get_change(current_changeset, field) do
        put_change(current_changeset, field, String.trim(value))
      else
        current_changeset
      end
    end)
  end

  defp convert_username_to_lowercase(changeset) do
    if username = get_change(changeset, :username) do
      put_change(changeset, :username, String.downcase(username))
    else
      changeset
    end
  end

  defp convert_email_to_lowercase(changeset) do
    if email = get_change(changeset, :email) do
      put_change(changeset, :email, String.downcase(email))
    else
      changeset
    end
  end
end

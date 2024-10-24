defmodule Slax.Accounts.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias Slax.Accounts.User

  schema "profiles" do
    field :bio, :string
    field :location, :string
    field :website, :string
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :location, :website, :user_id])
    |> validate_required([:user_id])
    |> validate_length(:bio, max: 500)
    |> validate_length(:location, max: 100)
    |> validate_length(:website, max: 255)
    |> validate_website_format()
  end

  defp validate_website_format(changeset) do
    validate_change(changeset, :website, fn :website, website ->
      if is_nil(website) || website == "" do
        []
      else
        case URI.parse(website) do
          %URI{scheme: scheme, host: host} when not is_nil(scheme) and not is_nil(host) -> []
          _ -> [website: "must be a valid URL"]
        end
      end
    end)
  end
end

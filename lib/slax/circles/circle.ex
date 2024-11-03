# lib/slax/circles/circle.ex
defmodule Slax.Circles.Circle do
  use Ecto.Schema
  import Ecto.Changeset
  alias Slax.Accounts.User

  schema "circles" do
    field :name, :string
    field :description, :string
    field :max_students, :integer, default: 25
    field :circle_type, Ecto.Enum, values: [:meditation, :yoga, :other]
    field :invitation_token, :string

    belongs_to :creator, User
    many_to_many :members, User, join_through: "circle_memberships"

    timestamps()
  end

  @doc false
  def changeset(circle, attrs) do
    circle
    |> cast(attrs, [:name, :description, :max_students, :circle_type])
    |> validate_required([:name, :description, :circle_type])
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:description, max: 500)
    |> validate_number(:max_students, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_inclusion(:circle_type, [:meditation, :yoga, :other])
    |> put_invitation_token()
  end

  defp put_invitation_token(changeset) do
    if changeset.valid? && !get_field(changeset, :invitation_token) do
      put_change(changeset, :invitation_token, generate_invitation_token())
    else
      changeset
    end
  end

  defp generate_invitation_token do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end
end

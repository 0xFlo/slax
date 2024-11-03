# lib/slax/circles.ex
defmodule Slax.Circles do
  import Ecto.Query
  alias Slax.Repo
  alias Slax.Circles.Circle
  alias Slax.Accounts.User

  def list_user_circles(%User{} = user) do
    Repo.all(
      from c in Circle,
        where: c.creator_id == ^user.id,
        order_by: [desc: c.inserted_at]
    )
  end

  def get_circle!(id), do: Repo.get!(Circle, id)

  def create_circle(%User{} = creator, attrs \\ %{}) do
    %Circle{}
    |> Circle.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:creator, creator)
    |> Repo.insert()
  end

  def update_circle(%Circle{} = circle, attrs) do
    circle
    |> Circle.changeset(attrs)
    |> Repo.update()
  end

  def delete_circle(%Circle{} = circle) do
    Repo.delete(circle)
  end

  def change_circle(%Circle{} = circle, attrs \\ %{}) do
    Circle.changeset(circle, attrs)
  end

  def get_circle_by_invitation!(token) do
    Repo.get_by!(Circle, invitation_token: token)
  end
end

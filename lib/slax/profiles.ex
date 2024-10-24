defmodule Slax.Profiles do
  import Ecto.Query
  alias Slax.Repo
  alias Slax.Accounts.{Profile, User}

  def get_profile_by_username(username) when is_binary(username) do
    User
    |> where(username: ^username)
    |> join(:left, [u], p in assoc(u, :profile))
    |> preload([u, p], profile: p)
    |> Repo.one()
  end

  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  def ensure_profile_exists(%User{} = user) do
    case Repo.get_by(Profile, user_id: user.id) do
      nil ->
        %Profile{}
        |> Profile.changeset(%{user_id: user.id})
        |> Repo.insert()

      profile ->
        {:ok, profile}
    end
  end
end

defmodule Slax.Profiles do
  @moduledoc """
  The Profiles context.
  """

  import Ecto.Query
  alias Slax.Repo
  alias Slax.Accounts.User
  alias Slax.Profiles.Profile

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
        create_profile(user)

      profile ->
        {:ok, profile}
    end
  end

  def create_profile(%User{} = user) do
    %Profile{}
    |> Profile.changeset(%{user_id: user.id})
    |> Repo.insert()
  end
end

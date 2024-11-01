defmodule Slax.Repo.Migrations.AddSocialLinksToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :github_handle, :string
      add :twitter_handle, :string
      add :linkedin_url, :string
      add :mastodon_handle, :string
    end
  end
end

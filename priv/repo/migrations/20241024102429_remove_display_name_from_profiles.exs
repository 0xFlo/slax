defmodule Slax.Repo.Migrations.RemoveDisplayNameFromProfiles do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      remove :display_name
    end
  end
end

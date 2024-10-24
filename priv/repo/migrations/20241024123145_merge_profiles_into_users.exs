defmodule Slax.Repo.Migrations.MergeProfilesIntoUsers do
  use Ecto.Migration

  def up do
    # Add profile columns to users
    alter table(:users) do
      add :bio, :string
      add :location, :string
      add :website, :string
    end

    # Copy data from profiles to users
    execute """
    UPDATE users
    SET bio = (SELECT bio FROM profiles WHERE profiles.user_id = users.id),
        location = (SELECT location FROM profiles WHERE profiles.user_id = users.id),
        website = (SELECT website FROM profiles WHERE profiles.user_id = users.id)
    """

    # Drop profiles table
    drop table(:profiles)
  end

  def down do
    create table(:profiles) do
      add :bio, :string
      add :location, :string
      add :website, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:profiles, [:user_id])

    # Copy data back to profiles
    execute """
    INSERT INTO profiles (bio, location, website, user_id, inserted_at, updated_at)
    SELECT bio, location, website, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    FROM users
    WHERE bio IS NOT NULL OR location IS NOT NULL OR website IS NOT NULL
    """

    alter table(:users) do
      remove :bio
      remove :location
      remove :website
    end
  end
end

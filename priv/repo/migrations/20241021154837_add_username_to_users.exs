defmodule Slax.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
    end

    # Optionally, if you want all usernames to be unique:
    create unique_index(:users, [:username])
  end
end

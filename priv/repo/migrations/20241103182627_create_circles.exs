defmodule Slax.Repo.Migrations.CreateCircles do
  use Ecto.Migration

  def change do
    create table(:circles) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :max_students, :integer, null: false, default: 25
      add :circle_type, :string, null: false
      add :invitation_token, :string, null: false
      add :creator_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:circles, [:invitation_token])
    create index(:circles, [:creator_id])

    create table(:circle_memberships) do
      add :circle_id, references(:circles, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:circle_memberships, [:circle_id, :user_id])
  end
end

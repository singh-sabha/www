defmodule SinghSabha.Repo.Migrations.CreateEventsTable do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :registrant_full_name, :string
      add :registrant_email, :string
      add :registrant_phone_number, :string
      add :type, references(:event_types), null: false
      add :start, :utc_datetime, null: false
      add :end, :utc_datetime, null: false
      add :occassion, :string, null: false
      add :note, :text
      add :is_verified, :boolean, default: false, null: false
      add :is_public, :boolean, default: false, null: false
      add :is_deposit_paid, :boolean, default: false, null: false

      timestamps()
    end

    create index(:events, [:type])
    create index(:events, [:start])
  end
end

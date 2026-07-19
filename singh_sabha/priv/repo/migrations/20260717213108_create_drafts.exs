defmodule SinghSabha.Repo.Migrations.CreateDrafts do
  use Ecto.Migration

  def change do
    create table(:drafts) do
      add :image_path, :string
      add :status, :string
      add :event_id, references(:events)

      timestamps(type: :utc_datetime)
    end

    create index(:drafts, [:event_id])
  end
end

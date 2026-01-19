defmodule SinghSabha.Repo.Migrations.CreateEventTypesTable do
  use Ecto.Migration

  def change do
    create table(:event_types) do
      add :display_name, :string, null: false
      add :description, :text, null: false
      add :is_requestable, :boolean, default: false
      add :deposit, :decimal, precision: 10, scale: 2, default: 0.00, null: false

      timestamps()
    end
  end
end

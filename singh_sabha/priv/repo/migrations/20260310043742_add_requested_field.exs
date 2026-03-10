defmodule SinghSabha.Repo.Migrations.AddRequestedField do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :requested, :date, null: true
      modify :start, :utc_datetime, null: true
      modify :end, :utc_datetime, null: true
    end
  end
end

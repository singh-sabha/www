defmodule SinghSabha.Repo.Migrations.AddFullNameField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :full_name, :string, null: false, default: ""
    end
  end
end

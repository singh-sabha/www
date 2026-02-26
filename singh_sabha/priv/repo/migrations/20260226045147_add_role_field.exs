defmodule SinghSabha.Repo.Migrations.AddRoleField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, null: false, default: "user"
    end

    create constraint(:users, :valid_role, check: "role IN ('user', 'mod', 'admin')")
  end
end

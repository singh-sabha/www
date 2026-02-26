defmodule SinghSabha.Repo.Migrations.DropIsAdminField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :is_admin, :boolean, default: false
    end
  end
end

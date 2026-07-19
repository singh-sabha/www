defmodule SinghSabha.Repo.Migrations.AddDraftIdField do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :draft_id, references(:drafts, on_delete: :nilify_all)
    end

    create index(:events, [:draft_id])
  end
end

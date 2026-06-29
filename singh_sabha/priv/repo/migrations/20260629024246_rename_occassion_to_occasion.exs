defmodule SinghSabha.Repo.Migrations.RenameOccassionToOcasion do
  use Ecto.Migration

  def change do
    rename table(:events), :occassion, to: :occasion
  end
end

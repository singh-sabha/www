defmodule SinghSabha.Drafts.Draft do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drafts" do
    field :image_path, :string
    field :status, :string

    has_many :events, SinghSabha.Events.Event

    timestamps()
  end

  @doc false
  def changeset(draft, attrs) do
    draft
    |> cast(attrs, [:image_path, :status])
    |> validate_required([:image_path, :status])
  end
end

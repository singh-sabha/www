defmodule SinghSabha.Events.EventType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_types" do
    field :display_name, :string
    field :description, :string
    field :is_requestable, :boolean, default: false
    field :deposit, :decimal

    has_many :events, SinghSabha.Events.Event, foreign_key: :type

    timestamps()
  end

  def changeset(event_type, attrs) do
    event_type
    |> cast(attrs, [:display_name, :description, :is_requestable, :deposit])
    |> validate_required([:display_name])
    |> validate_number(:deposit, greater_than_or_equal_to: Decimal.new("0"))
  end
end

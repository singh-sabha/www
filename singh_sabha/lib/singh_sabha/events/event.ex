defmodule SinghSabha.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :registrant_full_name, :string
    field :registrant_email, :string
    field :registrant_phone_number, :string
    field :start, :utc_datetime
    field :end, :utc_datetime
    field :occassion, :string
    field :note, :string
    field :is_verified, :boolean, default: false
    field :is_public, :boolean, default: false
    field :is_deposit_paid, :boolean, default: false

    belongs_to :event_type, SinghSabha.Events.EventType, foreign_key: :type

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :registrant_full_name,
      :registrant_email,
      :registrant_phone_number,
      :type,
      :start,
      :end,
      :occassion,
      :note,
      :is_verified,
      :is_public,
      :is_deposit_paid
    ])
    |> validate_required([:type, :start, :end, :occassion])
    |> foreign_key_constraint(:type)
  end
end

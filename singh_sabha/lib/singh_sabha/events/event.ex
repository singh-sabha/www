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
    |> validate_event_period()
    |> validate_phone_number()
    |> validate_email()
    |> validate_full_name()
    |> foreign_key_constraint(:type)
  end

  def validate_event_period(changeset) do
    start_time = get_field(changeset, :start)
    end_time = get_field(changeset, :end)

    if start_time && end_time && DateTime.compare(end_time, start_time) == :lt do
      add_error(changeset, :end, "must be after the start time")
    else
      changeset
    end
  end

  def validate_phone_number(changeset) do
    phone = get_change(changeset, :registrant_phone_number)

    if phone && phone != "" do
      changeset
      |> validate_format(:registrant_phone_number, ~r/^\d+$/, message: "must contain only digits")
      |> validate_length(:registrant_phone_number, min: 10, max: 15)
    else
      changeset
    end
  end

  def validate_email(changeset) do
    email = get_change(changeset, :registrant_email)

    if email && email != "" do
      changeset
      |> validate_format(:registrant_email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
      |> validate_length(:registrant_email, max: 160)
    else
      changeset
    end
  end

  def validate_full_name(changeset) do
    name = get_change(changeset, :registrant_full_name)

    if name && name != "" do
      changeset
      |> validate_length(:registrant_full_name, min: 2, max: 100)
      |> validate_format(:registrant_full_name, ~r/^[a-zA-Z\s\-'\.]+$/,
        message: "must contain only letters, spaces, hyphens, apostrophes, and periods"
      )
    else
      changeset
    end
  end
end

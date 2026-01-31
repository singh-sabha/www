defmodule SinghSabha.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias SinghSabha.Repo

  alias SinghSabha.Events.{Event, EventType}

  @doc """
  Returns the list of events.
  """
  def list_events do
    Event
    |> Repo.all()
    |> Repo.preload(:event_type)
  end

  @doc """
  Returns the list of public events.
  """
  def list_public_events do
    from(e in Event,
      where: e.is_verified == true and e.is_deposit_paid == true
    )
    |> Repo.all()
    |> Repo.preload(:event_type)
    |> Enum.map(fn e ->
      %{e | registrant_email: nil, registrant_phone_number: nil}
    end)
  end

  @doc """
  Gets a single event.

  Raises if the Event does not exist.
  """
  def get_event!(id) do
    Repo.get!(Event, id)
    |> Repo.preload(:event_type)
  end

  @doc """
  Creates a event.
  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event.
  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Event.
  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns a data structure for tracking event changes.
  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  @doc """
  Returns the list of event types.
  """
  def list_event_types do
    Repo.all(EventType)
  end

  @doc """
  Returns the list of public event types.
  """
  def list_public_event_types do
    from(et in EventType,
      where: et.is_requestable == true
    )
    |> Repo.all()
  end

  @doc """
  Gets a single event_type.

  Raises if the Event type does not exist.
  """
  def get_event_type!(id) do
    Repo.get!(EventType, id)
  end

  @doc """
  Creates an event type.
  """
  def create_event_type(attrs \\ %{}) do
    %EventType{}
    |> EventType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event_type.
  """
  def update_event_type(%EventType{} = event_type, attrs) do
    event_type
    |> EventType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a EventType.
  """
  def delete_event_type(%EventType{} = event_type) do
    Repo.delete(event_type)
  end

  @doc """
  Returns a data structure for tracking event_type changes.
  """
  def change_event_type(%EventType{} = event_type, attrs \\ %{}) do
    EventType.changeset(event_type, attrs)
  end
end

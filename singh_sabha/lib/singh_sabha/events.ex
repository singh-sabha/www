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
  def list_events(:all) do
    from(e in Event,
      where: not is_nil(e.start) and not is_nil(e.end),
      order_by: e.start,
      preload: [:event_type]
    )
    |> Repo.all()
  end

  def list_events(:public) do
    from(e in Event,
      where:
        not is_nil(e.start) and not is_nil(e.end) and
          e.is_verified and
          e.is_deposit_paid and
          e.is_public,
      order_by: e.start,
      preload: [:event_type]
    )
    |> Repo.all()
    |> Enum.map(fn e ->
      %{e | registrant_email: nil, registrant_phone_number: nil}
    end)
  end

  def list_events(:pending) do
    from(e in Event,
      where:
        not is_nil(e.requested) and
          is_nil(e.start) and
          is_nil(e.end),
      order_by: e.requested,
      preload: [:event_type]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of public events for the given week.
  """
  def list_events_between_dates(:public, start_date, end_date) do
    start_dt = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_dt = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

    from(e in Event,
      where:
        e.is_verified and
          e.is_deposit_paid and
          e.is_public and
          e.start >= ^start_dt and
          e.start <= ^end_dt,
      order_by: e.start,
      preload: [:event_type]
    )
    |> Repo.all()
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
  Gets a single event.
  """
  def get_event(id) do
    Repo.get(Event, id)
    |> Repo.preload(:event_type)
  end

  @doc """
  Creates a event.
  """
  def create_event(attrs \\ %{}) do
    case Event.changeset(%Event{}, attrs)
         |> Repo.insert() do
      {:ok, event} -> {:ok, Repo.preload(event, :event_type)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Creates multiple events.
  """
  def create_events(attrs_list \\ [%{}]) do
    attrs_list
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {attrs, index}, multi ->
      Ecto.Multi.insert(multi, {:event, index}, Event.changeset(%Event{}, attrs))
    end)
    |> Repo.transact()
    |> case do
      {:ok, results} ->
        events =
          results
          |> Enum.sort_by(fn {{:event, index}, _event} -> index end)
          |> Enum.map(fn {_key, event} -> Repo.preload(event, :event_type) end)

        {:ok, events}

      {:error, _failed_key, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Books an event.
  """
  def book_event(attrs \\ %{}) do
    case Event.guest_changeset(%Event{}, attrs)
         |> Repo.insert() do
      {:ok, event} -> {:ok, Repo.preload(event, :event_type)}
      {:error, changeset} -> {:error, changeset}
    end
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
  Returns a data structure for tracking event changes.
  """
  def guest_change_event(%Event{} = event, attrs \\ %{}) do
    Event.guest_changeset(event, attrs)
  end

  @doc """
  Returns the list of event types.
  """
  def list_event_types(:all) do
    Repo.all(EventType)
  end

  def list_event_types(:public) do
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
  Gets a single event_type.
  """
  def get_event_type(id) do
    Repo.get(EventType, id)
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

defmodule SinghSabhaWeb.CalendarLive.Index do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.Presence

  alias SinghSabhaWeb.Helpers.{
    CalendarHelpers,
    TimezoneHelpers,
    UserHelpers,
    EventTypeHelpers
  }

  alias SinghSabhaWeb.Components.Modals.{BookEvent, CreateEvent}

  alias SinghSabhaWeb.CalendarLive.Modals.{EditEvent, ViewEvent}

  import SinghSabhaWeb.CalendarLive.Views.{
    Day,
    Week,
    Month,
    Agenda
  }

  alias SinghSabha.Events

  @impl true
  def mount(_params, _session, socket) do
    now = DateTime.now!(TimezoneHelpers.local())
    today = DateTime.to_date(now)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "global:presence")

      # TODO: could probably abstract this away; pretty sure we use it in multiple places
      seconds_until_next_minute = 60 - now.second

      milliseconds_until_next_minute =
        seconds_until_next_minute * 1000 - rem(now.microsecond |> elem(0), 1000)

      Process.send_after(self(), :tick, milliseconds_until_next_minute)
    end

    socket =
      socket
      |> assign(:page_title, "Calendar")
      |> assign(:live_users, get_presence_users())
      |> assign(:view_mode, :month)
      |> assign(:current_date, today)
      |> assign(:current_time, now)
      |> assign(:selected_date, today)
      |> assign(:working_hours, %{start: 4, end: 20})
      |> assign(:visible_hours, :all_hours)
      |> assign(:selected_event, nil)
      |> load_events()
      |> load_event_types()

    {:ok, socket}
  end

  @impl true
  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :view_mode, String.to_atom(view))}
  end

  def handle_event("prev_period", _, socket) do
    new_date = shift_date(socket.assigns.current_date, socket.assigns.view_mode, -1)
    {:noreply, socket |> assign(:current_date, new_date) |> load_events()}
  end

  def handle_event("next_period", _, socket) do
    new_date = shift_date(socket.assigns.current_date, socket.assigns.view_mode, 1)
    {:noreply, socket |> assign(:current_date, new_date) |> load_events()}
  end

  def handle_event("change_view_to_today", _, socket) do
    {:noreply, socket |> assign(:current_date, socket.assigns.current_time)}
  end

  def handle_event("change_view_to_date", %{"date" => date}, socket) do
    case Date.from_iso8601(date) do
      {:ok, parsed_date} ->
        {:noreply,
         socket
         |> assign(:current_date, parsed_date)
         |> assign(:view_mode, :day)
         |> load_events()}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("date-selected", %{"date" => date}, socket) do
    case Date.from_iso8601(date) do
      {:ok, date} ->
        {:noreply,
         socket
         |> assign(:selected_date, date)
         |> assign(:current_date, date)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("view_event", %{"event-id" => event_id}, socket) do
    event = CalendarHelpers.find_event(event_id, socket.assigns.events)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "view_event_modal"})}
  end

  def handle_event("create_or_book_event", %{"date" => date, "time" => start_time}, socket) do
    if UserHelpers.is_privileged?(socket.assigns.current_scope) do
      start_time =
        if String.contains?(start_time, "."),
          do: String.to_float(start_time),
          else: String.to_integer(start_time) / 1

      time_to_string = fn time ->
        hour = trunc(time)
        minute = if rem(trunc(time * 2), 2) == 1, do: 30, else: 0

        "#{String.pad_leading(Integer.to_string(hour), 2, "0")}:#{String.pad_leading(Integer.to_string(minute), 2, "0")}:00"
      end

      end_time = start_time + 0.5

      {:ok, start_datetime} =
        NaiveDateTime.from_iso8601("#{date}T#{time_to_string.(start_time)}Z")

      {:ok, end_datetime} = NaiveDateTime.from_iso8601("#{date}T#{time_to_string.(end_time)}Z")

      send_update(CreateEvent,
        id: "create_event_modal",
        start_datetime: start_datetime,
        end_datetime: end_datetime
      )

      {:noreply, push_event(socket, "open-modal", %{id: "create_event_modal"})}
    else
      {:ok, requested_date} = Date.from_iso8601(date)

      send_update(BookEvent,
        id: "book_event_modal",
        requested_date: requested_date
      )

      {:noreply, push_event(socket, "open-modal", %{id: "book_event_modal"})}
    end
  end

  def handle_event("create_or_book_event", _params, socket) do
    modal_id =
      if UserHelpers.is_privileged?(socket.assigns.current_scope),
        do: "create_event_modal",
        else: "book_event_modal"

    {:noreply, push_event(socket, "open-modal", %{id: modal_id})}
  end

  def handle_event("edit_event", %{"event-id" => event_id}, socket) do
    event = CalendarHelpers.find_event(event_id, socket.assigns.events)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "edit_event_modal"})}
  end

  def handle_event("delete_event", %{"event-id" => event_id}, socket) do
    event = CalendarHelpers.find_event(event_id, socket.assigns.events)

    case Events.delete_event(event) do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_deleted, event})

        {:noreply,
         socket
         |> push_event("close-modal", %{id: "view_event_modal"})}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete event. Please try again.")
         |> push_event("close-modal", %{id: "view_event_modal"})}
    end
  end

  def handle_event("open_assistant", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/calendar/assistant")}
  end

  @impl true
  def handle_info({:put_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 30_000)

    {:noreply, assign(socket, :current_time, DateTime.now!(TimezoneHelpers.local()))}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    if timer = socket.assigns[:presence_timer], do: Process.cancel_timer(timer)
    timer = Process.send_after(self(), :update_presence, 150)
    {:noreply, assign(socket, :presence_timer, timer)}
  end

  def handle_info(:update_presence, socket) do
    {:noreply, assign(socket, :live_users, get_presence_users())}
  end

  def handle_info({:event_created, _event}, socket) do
    {:noreply, load_events(socket)}
  end

  def handle_info({:event_updated, updated_event}, socket) do
    socket =
      socket
      |> load_events()
      |> then(fn socket ->
        if socket.assigns.selected_event &&
             socket.assigns.selected_event.id == updated_event.id do
          assign(
            socket,
            :selected_event,
            Events.get_event!(updated_event.id) |> TimezoneHelpers.convert_event_to_local()
          )
        else
          socket
        end
      end)

    {:noreply, socket}
  end

  def handle_info({:event_deleted, _event}, socket) do
    {:noreply,
     socket
     |> assign(:selected_event, nil)
     |> load_events()}
  end

  defp get_presence_users do
    Presence.list("global:presence")
    |> Map.values()
    |> Enum.map(fn %{metas: [meta | _]} -> meta end)
    |> Enum.uniq_by(& &1.user_id)
  end

  defp load_events(socket) do
    events =
      case UserHelpers.is_privileged?(socket.assigns.current_scope) do
        true -> Events.list_events(:all)
        false -> Events.list_events(:public)
      end
      |> Enum.map(fn event ->
        %{
          event
          | start: TimezoneHelpers.utc_to_local(event.start),
            end: TimezoneHelpers.utc_to_local(event.end)
        }
      end)

    assign(socket, :events, events)
  end

  defp load_event_types(socket) do
    case UserHelpers.is_privileged?(socket.assigns.current_scope) do
      true -> assign(socket, :event_types, Events.list_event_types(:all))
      false -> assign(socket, :event_types, Events.list_event_types(:public))
    end
  end

  defp shift_date(date, :month, offset), do: Date.add(date, offset * 30)
  defp shift_date(date, :week, offset), do: Date.add(date, offset * 7)
  defp shift_date(date, :day, offset), do: Date.add(date, offset)
  defp shift_date(date, :agenda, offset), do: Date.add(date, offset * 30)

  defp period_label(date, :month), do: Calendar.strftime(date, "%B %Y")

  defp period_label(date, :week) do
    week_start = Date.beginning_of_week(date, :sunday)
    week_end = Date.add(week_start, 6)
    "#{Calendar.strftime(week_start, "%b %d")} - #{Calendar.strftime(week_end, "%b %d, %Y")}"
  end

  defp period_label(date, :day), do: Calendar.strftime(date, "%A, %B %d, %Y")
  defp period_label(date, :agenda), do: Calendar.strftime(date, "%A, %B %d, %Y")
end

defmodule SinghSabhaWeb.CalendarLive.Index do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.Presence

  alias SinghSabhaWeb.Helpers.{
    Event,
    Timezone,
    User,
    Path,
    Colour
  }

  alias SinghSabhaWeb.Components.Modals.{BookEvent, CreateEvent, EditEvent}

  alias SinghSabhaWeb.Components.Modals.ViewEvent

  import SinghSabhaWeb.CalendarLive.Views.{
    Day,
    Week,
    Month,
    Agenda
  }

  alias SinghSabha.Events

  @impl true
  def mount(_params, _session, socket) do
    now = DateTime.now!(Timezone.local())

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "global:presence")
      Process.send_after(self(), :tick, Timezone.schedule_next_tick(now))
    end

    event_types =
      if User.privileged?(socket.assigns.current_scope) do
        Events.list_event_types(:all)
      else
        Events.list_event_types(:public)
      end

    socket =
      socket
      |> assign(:page_title, "Calendar")
      |> assign(:live_users, get_presence_users())
      |> assign(:current_time, now)
      |> assign(:working_hours, %{start: 4, end: 20})
      |> assign(:visible_hours, :all_hours)
      |> assign(:selected_event, nil)
      |> assign(:event_types, event_types)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    view = parse_view(params["view"])
    date = parse_date(params["date"])

    socket =
      socket
      |> assign(:view_mode, view)
      |> assign(:current_date, date)
      |> assign(:origin_path, %{view: view, date: date})
      |> load_events()

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("prev_period", _, socket) do
    new_date = shift_date(socket.assigns.current_date, socket.assigns.view_mode, -1)

    {:noreply, push_patch(socket, to: Path.calendar(socket.assigns.origin_path, date: new_date))}
  end

  def handle_event("next_period", _, socket) do
    new_date = shift_date(socket.assigns.current_date, socket.assigns.view_mode, 1)

    {:noreply, push_patch(socket, to: Path.calendar(socket.assigns.origin_path, date: new_date))}
  end

  def handle_event("date-selected", %{"date" => date}, socket) do
    case Date.from_iso8601(date) do
      {:ok, date} ->
        {:noreply, push_patch(socket, to: Path.calendar(socket.assigns.origin_path, date: date))}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("delete_event", %{"event-id" => event_id}, socket) do
    event = Event.find_event(event_id, socket.assigns.events)

    case Events.delete_event(event) do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_deleted, event})

        {:noreply,
         socket
         |> put_flash(:success, "Event deleted successfully!")
         |> push_patch(to: Path.calendar(socket.assigns.origin_path))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete event. Please try again.")
         |> push_patch(to: Path.calendar(socket.assigns.origin_path))}
    end
  end

  @impl true
  def handle_info({:put_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 30_000)

    {:noreply, assign(socket, :current_time, DateTime.now!(Timezone.local()))}
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
            Events.get_event!(updated_event.id) |> Timezone.convert_event_to_local()
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

  defp parse_view(view) when view in ~w(day week month agenda), do: String.to_existing_atom(view)
  defp parse_view(_view), do: :month

  defp parse_date(nil), do: Date.utc_today()

  defp parse_date(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> Date.utc_today()
    end
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :selected_event, nil)
  end

  defp apply_action(socket, :new, params) do
    if User.privileged?(socket.assigns.current_scope) do
      case build_event_window(params) do
        {:ok, start_datetime, end_datetime} ->
          send_update(CreateEvent,
            id: "create_event_modal",
            start_datetime: start_datetime,
            end_datetime: end_datetime
          )

          assign(socket, :selected_event, nil)

        :no_slot ->
          assign(socket, :selected_event, nil)
      end
    else
      case params do
        %{"date" => date} ->
          {:ok, requested_date} = Date.from_iso8601(date)
          send_update(BookEvent, id: "book_event_modal", requested_date: requested_date)
          assign(socket, :selected_event, nil)

        _ ->
          assign(socket, :selected_event, nil)
      end
    end
  end

  defp apply_action(socket, :show, %{"id" => event_id}) do
    with event when not is_nil(event) <- Events.get_event(event_id),
         true <- event.is_public or User.privileged?(socket.assigns.current_scope) do
      assign(socket, :selected_event, event)
    else
      nil ->
        socket
        |> put_flash(:error, "Event not found.")
        |> push_patch(to: Path.calendar(socket.assigns.origin_path))

      false ->
        socket
        |> put_flash(:warning, "Event not available.")
        |> push_patch(to: Path.calendar(socket.assigns.origin_path))
    end
  end

  defp apply_action(socket, :edit, %{"id" => event_id}) do
    case Events.get_event(event_id) do
      nil ->
        socket
        |> put_flash(:error, "Event not found.")
        |> push_patch(to: Path.calendar(socket.assigns.origin_path))

      event ->
        assign(socket, :selected_event, event)
    end
  end

  defp get_presence_users do
    Presence.list("global:presence")
    |> Map.values()
    |> Enum.map(fn %{metas: [meta | _]} -> meta end)
    |> Enum.uniq_by(& &1.user_id)
  end

  defp load_events(socket) do
    events =
      case User.privileged?(socket.assigns.current_scope) do
        true -> Events.list_events(:all)
        false -> Events.list_events(:public)
      end
      |> Enum.map(fn event ->
        %{
          event
          | start: Timezone.utc_to_local(event.start),
            end: Timezone.utc_to_local(event.end)
        }
      end)

    assign(socket, :events, events)
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

  defp build_event_window(%{"date" => date, "time" => start_time}) do
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

    with {:ok, start_datetime} <-
           NaiveDateTime.from_iso8601("#{date}T#{time_to_string.(start_time)}Z"),
         {:ok, end_datetime} <-
           NaiveDateTime.from_iso8601("#{date}T#{time_to_string.(end_time)}Z") do
      {:ok, start_datetime, end_datetime}
    else
      _ -> :no_slot
    end
  end

  defp build_event_window(_params), do: :no_slot
end

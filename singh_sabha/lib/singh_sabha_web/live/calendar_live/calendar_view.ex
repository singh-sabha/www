defmodule SinghSabhaWeb.CalendarLive do
  use SinghSabhaWeb, :live_view

  import SinghSabhaWeb.Helpers.CalendarHelpers

  alias SinghSabhaWeb.CalendarLive.{
    MonthView,
    WeekView,
    DayView,
    CreateEventModal,
    EditEventModal,
    ViewEventModal
  }

  alias SinghSabha.Events

  def render(assigns) do
    ~H"""
    <div id="success">{Phoenix.Flash.get(@flash, :success)}</div>
    <div class="p-4 h-screen">
      <div class="border border-base-300 rounded-md h-full flex flex-col">
        <div class="p-4 space-y-4 lg:space-y-0 shrink-0">
          <div class="flex flex-col gap-4 lg:flex-row lg:justify-between lg:items-center">
            <div class="flex gap-4 items-start">
              <button
                class="flex size-16 flex-col overflow-hidden rounded-lg border border-base-300 cursor-pointer shrink-0"
                phx-click="change_view_to_today"
              >
                <p class="flex h-6 w-full items-center justify-center bg-black text-center text-xs font-semibold text-white">
                  {String.upcase(get_month_label(@current_time, :abbreviation))}
                </p>
                <p class="flex flex-1 w-full items-center justify-center text-lg font-bold">
                  {@current_time.day}
                </p>
              </button>
              <div class="space-y-1">
                <div class="flex items-center space-x-2">
                  <span class="text-lg font-semibold">
                    {get_month_label(@current_date, :full)} {@current_date.year}
                  </span>
                  <div class="badge badge-outline badge-primary">
                    <% period_events_total = get_total_events(@events, @current_date, @view_mode) %>
                    {"#{period_events_total} event#{if period_events_total == 1, do: "", else: "s"}"}
                  </div>
                </div>
                <div class="space-x-4">
                  <button phx-click="prev_period" class="btn btn-sm btn-square">
                    <.icon name="hero-chevron-left" />
                  </button>
                  <span class="text-sm text-base-content/50">
                    {period_label(@current_date, @view_mode)}
                  </span>
                  <button phx-click="next_period" class="btn btn-sm btn-square">
                    <.icon name="hero-chevron-right" />
                  </button>
                </div>
              </div>
            </div>

            <div class="space-x-2">
              <div class="join w-full lg:w-auto">
                <button
                  class="btn join-item flex-1 lg:flex-none"
                  phx-click="change_view"
                  phx-value-view="month"
                >
                  Month
                </button>
                <button
                  class="btn join-item flex-1 lg:flex-none"
                  phx-click="change_view"
                  phx-value-view="week"
                >
                  Week
                </button>
                <button
                  class="btn join-item flex-1 lg:flex-none"
                  phx-click="change_view"
                  phx-value-view="day"
                >
                  Day
                </button>
              </div>

              <button class="btn" onclick="create_event_modal.showModal()">
                <.icon name="hero-plus-circle" /> Create Event
              </button>
            </div>
          </div>
        </div>

        <div class="flex-1 min-h-0 overflow-auto">
          <%= if @view_mode == :month do %>
            <MonthView.view
              current_date={@current_date}
              events={@events}
            />
          <% end %>
          <%= if @view_mode == :week do %>
            <WeekView.view
              current_date={@current_date}
              current_time={@current_time}
              events={@events}
              working_hours={@working_hours}
              visible_hours={@visible_hours}
            />
          <% end %>
          <%= if @view_mode == :day do %>
            <DayView.view
              current_date={@current_date}
              current_time={@current_time}
              events={@events}
              working_hours={@working_hours}
              visible_hours={@visible_hours}
            />
          <% end %>
        </div>
      </div>

      <.live_component
        module={ViewEventModal}
        id="view_event_modal"
        selected_event={@selected_event}
      />
      <.live_component
        module={CreateEventModal}
        id="create_event_modal"
        event_types={@event_types}
      />
      <.live_component
        module={EditEventModal}
        id="edit_event_modal"
        selected_event={@selected_event}
      />

      <div phx-hook="ModalManager" id="modal-manager"></div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    now = DateTime.now!("America/Vancouver")
    today = DateTime.to_date(now)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")

      seconds_until_next_minute = 60 - now.second

      milliseconds_until_next_minute =
        seconds_until_next_minute * 1000 - rem(now.microsecond |> elem(0), 1000)

      Process.send_after(self(), :tick, milliseconds_until_next_minute)
    end

    socket =
      socket
      |> assign(:view_mode, :month)
      |> assign(:current_date, today)
      |> assign(:current_time, now)
      |> assign(:selected_date, today)
      |> assign(:working_hours, %{start: 4, end: 20})
      |> assign(:visible_hours, :working_hours)
      |> assign(:selected_event, nil)
      |> load_events()
      |> load_event_types()

    {:ok, socket}
  end

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
    today = DateTime.to_date(DateTime.now!("America/Vancouver"))
    {:noreply, socket |> assign(:current_date, today) |> load_events()}
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

  def handle_event("open_create_modal", _, socket) do
    send_update(CreateEventModal, id: "create_event_modal", action: :reset)

    {:noreply, push_event(socket, "open-modal", %{id: "create_event_modal"})}
  end

  def handle_event("view_event", %{"event-id" => event_id}, socket) do
    event =
      Enum.find(socket.assigns.events, fn event ->
        event.id == String.to_integer(event_id)
      end)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "view_event_modal"})}
  end

  def handle_event("edit_event", %{"event-id" => event_id}, socket) do
    event =
      Enum.find(socket.assigns.events, fn event ->
        event.id == String.to_integer(event_id)
      end)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "edit_event_modal"})}
  end

  def handle_event("delete_event", %{"event-id" => event_id}, socket) do
    event =
      Enum.find(socket.assigns.events, fn event ->
        event.id == String.to_integer(event_id)
      end)

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

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 30_000)

    {:noreply, assign(socket, :current_time, DateTime.now!("America/Vancouver"))}
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
          assign(socket, :selected_event, Events.get_event!(updated_event.id))
        else
          socket
        end
      end)

    {:noreply, socket}
  end

  def handle_info({:event_deleted, _event}, socket) do
    {:noreply, load_events(socket)}
  end

  defp load_events(socket) do
    events = Events.list_events()

    events_in_local_tz =
      Enum.map(events, fn event ->
        %{
          event
          | start: DateTime.shift_zone!(event.start, "America/Vancouver"),
            end: DateTime.shift_zone!(event.end, "America/Vancouver")
        }
      end)

    socket
    |> assign(:events, events_in_local_tz)
  end

  defp load_event_types(socket) do
    socket
    |> assign(:event_types, Events.list_event_types())
  end

  defp shift_date(date, :month, offset), do: Date.add(date, offset * 30)
  defp shift_date(date, :week, offset), do: Date.add(date, offset * 7)
  defp shift_date(date, :day, offset), do: Date.add(date, offset)

  defp period_label(date, :month), do: Calendar.strftime(date, "%B %Y")

  defp period_label(date, :week) do
    week_start = Date.beginning_of_week(date, :sunday)
    week_end = Date.add(week_start, 6)
    "#{Calendar.strftime(week_start, "%b %d")} - #{Calendar.strftime(week_end, "%b %d, %Y")}"
  end

  defp period_label(date, :day), do: Calendar.strftime(date, "%A, %B %d, %Y")
end

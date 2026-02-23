defmodule SinghSabhaWeb.CalendarLive do
  alias SinghSabhaWeb.Helpers.EventTypeHelpers
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.Presence

  alias SinghSabhaWeb.Helpers.{
    CalendarHelpers,
    TimezoneHelpers,
    UserHelpers
  }

  alias SinghSabha.Events.EventNotifier

  alias SinghSabhaWeb.CalendarLive.{
    MonthView,
    WeekView,
    DayView,
    AgendaView,
    CreateEventModal,
    EditEventModal,
    ViewEventModal,
    RejectEventModal
  }

  alias SinghSabha.Events

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="h-[calc(100vh-8.1rem)]">
        <div class="border border-base-300 rounded-md h-full flex flex-col">
          <div class="p-4 space-y-4 lg:space-y-0 shrink-0">
            <div class="flex flex-col gap-4 lg:flex-row lg:justify-between lg:items-center">
              <div class="flex space-x-4 items-start">
                <button
                  class="flex size-15 lg:size-16 flex-col overflow-hidden rounded-lg border border-base-300 cursor-pointer shrink-0"
                  phx-click="change_view_to_today"
                >
                  <p class="flex h-6 w-full items-center justify-center bg-primary text-center text-xs font-semibold text-primary-content">
                    {String.upcase(CalendarHelpers.get_month_label(@current_time, :abbreviation))}
                  </p>
                  <p class="flex flex-1 w-full items-center justify-center text-md lg:text-lg font-bold">
                    {@current_time.day}
                  </p>
                </button>

                <div class="space-y-1 min-w-0 flex-1">
                  <div class="flex items-center gap-2">
                    <span class="text-md lg:text-lg font-semibold shrink-0">
                      {CalendarHelpers.get_month_label(@current_date, :full)} {@current_date.year}
                    </span>
                    <div class="badge badge-sm lg:badge-md badge-primary text-[10px] lg:text-md shrink-0">
                      <% period_events_total =
                        CalendarHelpers.get_total_events(@events, @current_date, @view_mode) %>
                      {"#{period_events_total} event#{if period_events_total == 1, do: "", else: "s"}"}
                    </div>
                    <div class="badge badge-sm badge-soft gap-1 lg:hidden text-[10px] lg:text-md  shrink-0">
                      <span class={[
                        "size-1.5 rounded-full inline-block",
                        EventTypeHelpers.dot_colour(:green)
                      ]}>
                      </span>
                      {length(@live_users)} online
                    </div>
                  </div>

                  <div class="flex items-center gap-2">
                    <button phx-click="prev_period" class="btn btn-sm btn-square shrink-0">
                      <.icon name="hero-chevron-left" />
                    </button>
                    <p class="text-sm text-base-content/50 truncate flex-1 lg:flex-none text-center lg:text-left">
                      {period_label(@current_date, @view_mode)}
                    </p>
                    <button phx-click="next_period" class="btn btn-sm btn-square shrink-0">
                      <.icon name="hero-chevron-right" />
                    </button>
                  </div>
                </div>
              </div>

              <div class="hidden lg:flex items-center gap-2">
                <div class="flex -space-x-2">
                  <%= for user <- Enum.take(@live_users, 5) do %>
                    <div
                      tabindex="0"
                      class="avatar tooltip tooltip-bottom"
                      data-tip={
                        if @current_scope && user.user_id == @current_scope.user.id,
                          do: "You",
                          else: "User #{user.user_id}"
                      }
                    >
                      <div
                        class="size-8 rounded-full flex items-center justify-center border-2 border-base-100"
                        style={"background: linear-gradient(135deg, #{UserHelpers.generate_gradient_colours(user.user_id)})"}
                      >
                      </div>
                    </div>
                  <% end %>
                  <%= if length(@live_users) > 5 do %>
                    <div class="size-8 rounded-full bg-base-300 flex items-center justify-center text-xs font-bold border-2 border-base-100">
                      +{length(@live_users) - 5}
                    </div>
                  <% end %>
                </div>
                <span class="text-sm text-base-content/50">{length(@live_users)} online</span>
              </div>

              <div class="space-y-2 lg:space-y-0 lg:space-x-4 lg:flex lg:items-center">
                <div class="join w-full lg:w-auto">
                  <button
                    class={[
                      "btn join-item flex-1 lg:flex-none",
                      @view_mode == :agenda && "btn-active"
                    ]}
                    phx-click="change_view"
                    phx-value-view="agenda"
                  >
                    <.icon name="hero-list-bullet" class="size-4" />
                  </button>
                  <button
                    class={[
                      "btn join-item flex-1 lg:flex-none",
                      @view_mode == :month && "btn-active"
                    ]}
                    phx-click="change_view"
                    phx-value-view="month"
                  >
                    <.icon name="hero-calendar-days" class="size-4" />
                  </button>
                  <button
                    class={[
                      "btn join-item flex-1 lg:flex-none",
                      @view_mode == :week && "btn-active"
                    ]}
                    phx-click="change_view"
                    phx-value-view="week"
                  >
                    <.icon name="hero-calendar-date-range" class="size-4" />
                  </button>
                  <button
                    class={[
                      "btn join-item flex-1 lg:flex-none",
                      @view_mode == :day && "btn-active"
                    ]}
                    phx-click="change_view"
                    phx-value-view="day"
                  >
                    <.icon name="hero-calendar" class="size-4" />
                  </button>
                </div>

                <button
                  class="btn btn-primary w-full lg:w-auto"
                  onclick="create_event_modal.showModal()"
                >
                  <span class="flex items-center gap-1">
                    <.icon name="hero-plus-circle" class="size-4" />
                    {if UserHelpers.is_admin?(@current_scope), do: "Create", else: "Book"} Event
                  </span>
                </button>
              </div>
            </div>
          </div>

          <div class="flex-1 min-h-0 overflow-auto">
            <%= if @view_mode == :agenda do %>
              <AgendaView.view
                current_date={@current_date}
                current_time={@current_time}
                current_scope={@current_scope}
                events={@events}
              />
            <% end %>

            <%= if @view_mode == :month do %>
              <MonthView.view
                current_date={@current_date}
                current_time={@current_time}
                current_scope={@current_scope}
                events={@events}
              />
            <% end %>
            <%= if @view_mode == :week do %>
              <WeekView.view
                current_date={@current_date}
                current_time={@current_time}
                current_scope={@current_scope}
                events={@events}
                working_hours={@working_hours}
                visible_hours={@visible_hours}
              />
            <% end %>
            <%= if @view_mode == :day do %>
              <DayView.view
                current_date={@current_date}
                current_time={@current_time}
                current_scope={@current_scope}
                events={@events}
                working_hours={@working_hours}
                visible_hours={@visible_hours}
              />
            <% end %>
          </div>
        </div>

        <.live_component
          module={CreateEventModal}
          id="create_event_modal"
          event_types={@event_types}
          current_scope={@current_scope}
        />
        <.live_component
          :if={@selected_event}
          module={ViewEventModal}
          id="view_event_modal"
          selected_event={@selected_event}
          current_scope={@current_scope}
        />
        <.live_component
          :if={@selected_event}
          module={EditEventModal}
          id="edit_event_modal"
          selected_event={@selected_event}
        />
        <.live_component
          module={RejectEventModal}
          id="reject_event_modal"
          selected_event={@selected_event}
        />

        <div phx-hook="ModalManager" id="modal-manager"></div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    now = DateTime.now!(TimezoneHelpers.local())
    today = DateTime.to_date(now)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "calendar:presence")

      current_user = socket.assigns.current_scope

      user_id =
        case current_user do
          nil -> UserHelpers.generate_user_id()
          _ -> current_user.user.id
        end

      {:ok, _} =
        Presence.track(self(), "calendar:presence", user_id, %{
          online_at: System.system_time(:second),
          user_id: user_id
        })

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
    event = find_event(event_id, socket.assigns.events)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "view_event_modal"})}
  end

  def handle_event("create_event", %{"date" => date, "time" => start_time}, socket) do
    start_time =
      if String.contains?(start_time, ".") do
        String.to_float(start_time)
      else
        String.to_integer(start_time) / 1
      end

    time_to_string = fn time ->
      hour = trunc(time)
      minute = if rem(trunc(time * 2), 2) == 1, do: 30, else: 0

      "#{String.pad_leading(Integer.to_string(hour), 2, "0")}:#{String.pad_leading(Integer.to_string(minute), 2, "0")}:00"
    end

    end_time = start_time + 0.5

    # Create event modal requires UTC hence the "Z"
    {:ok, start_datetime} = NaiveDateTime.from_iso8601("#{date}T#{time_to_string.(start_time)}Z")
    {:ok, end_datetime} = NaiveDateTime.from_iso8601("#{date}T#{time_to_string.(end_time)}Z")

    send_update(SinghSabhaWeb.CalendarLive.CreateEventModal,
      id: "create_event_modal",
      start_datetime: start_datetime,
      end_datetime: end_datetime
    )

    {:noreply, push_event(socket, "open-modal", %{id: "create_event_modal"})}
  end

  def handle_event("edit_event", %{"event-id" => event_id}, socket) do
    event = find_event(event_id, socket.assigns.events)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "edit_event_modal"})}
  end

  def handle_event("delete_event", %{"event-id" => event_id}, socket) do
    event = find_event(event_id, socket.assigns.events)

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

  def handle_event("approve_event", %{"event-id" => event_id}, socket) do
    event = find_event(event_id, socket.assigns.events)

    case Events.update_event(event, %{"is_verified" => true}) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          "events",
          {:event_updated, event}
        )

        EventNotifier.event_approved(event)

        {:noreply,
         socket
         |> put_flash(:success, "Event Approved! Email sent to user.")
         |> push_event("close-modal", %{id: "view_event_modal"})}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to approve event. Please try again.")
         |> push_event("close-modal", %{id: "view_event_modal"})}
    end
  end

  def handle_event("reject_event", %{"event-id" => event_id}, socket) do
    event = find_event(event_id, socket.assigns.events)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "reject_event_modal"})}
  end

  def handle_info({:put_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  def handle_info({:reject_event, event, reason}, socket) do
    case Events.delete_event(event) do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_deleted, event})

        EventNotifier.event_denied(event, reason)

        {:noreply,
         socket
         |> push_event("close-modal", %{id: "reject_event_modal"})}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete event. Please try again.")
         |> push_event("close-modal", %{id: "reject_event_modal"})}
    end
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 30_000)

    {:noreply, assign(socket, :current_time, DateTime.now!(TimezoneHelpers.local()))}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
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
    Presence.list("calendar:presence")
    |> Map.values()
    |> Enum.map(fn %{metas: [meta | _]} -> meta end)
  end

  defp load_events(socket) do
    events =
      case UserHelpers.is_admin?(socket.assigns.current_scope) do
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
    case UserHelpers.is_admin?(socket.assigns.current_scope) do
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

  defp find_event(event_id, events) do
    Enum.find(events, fn event ->
      event.id == String.to_integer(event_id)
    end)
  end
end

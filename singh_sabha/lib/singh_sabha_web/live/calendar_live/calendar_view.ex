defmodule SinghSabhaWeb.CalendarLive do
  use SinghSabhaWeb, :live_view

  import SinghSabhaWeb.Helpers.CalendarHelpers

  alias SinghSabhaWeb.CalendarLive.{MonthView, WeekView, DayView}

  def render(assigns) do
    ~H"""
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
    </div>
    """
  end

  def mount(_params, _session, socket) do
    now = DateTime.now!("America/Vancouver")
    today = DateTime.to_date(now)

    if connected?(socket) do
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
      |> load_events()

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

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 30_000)

    {:noreply, assign(socket, :current_time, DateTime.now!("America/Vancouver"))}
  end

  defp load_events(socket) do
    events = [
      %{
        id: 1,
        title: "Team Meeting",
        start: ~U[2026-01-15 10:00:00Z],
        end: ~U[2026-01-15 11:00:00Z],
        type: "Akhand Path"
      },
      %{
        id: 2,
        title: "Standup",
        start: ~U[2026-01-15 10:00:00Z],
        end: ~U[2026-01-15 10:15:00Z],
        type: "Akhand Path"
      },
      %{
        id: 3,
        title: "Review",
        start: ~U[2026-01-15 10:30:00Z],
        end: ~U[2026-01-15 11:00:00Z],
        type: "Akhand Path"
      },
      %{
        id: 4,
        title: "Lunch",
        start: ~U[2026-01-15 12:00:00Z],
        end: ~U[2026-01-15 13:00:00Z],
        type: "Akhand Path"
      },
      %{
        id: 5,
        title: "Dinner",
        start: ~U[2026-01-15 17:00:00Z],
        end: ~U[2026-01-15 19:00:00Z],
        type: "Akhand Path"
      },
      %{
        id: 6,
        title: "Project Review",
        start: ~U[2026-01-16 14:00:00Z],
        end: ~U[2026-01-16 16:00:00Z],
        type: "Akhand Path"
      },
      %{
        id: 7,
        title: "Conference",
        start: ~U[2026-01-13 09:00:00Z],
        end: ~U[2026-01-15 17:00:00Z],
        type: "Akhand Path"
      },
      %{
        id: 8,
        title: "Seminar",
        start: ~U[2026-01-13 09:00:00Z],
        end: ~U[2026-01-15 17:00:00Z],
        type: "Akhand Path"
      },
      %{
        id: 9,
        title: "Vacation",
        start: ~U[2026-01-20 00:00:00Z],
        end: ~U[2026-01-25 23:59:59Z],
        type: "Akhand Path"
      }
    ]

    assign(socket, :events, events)
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

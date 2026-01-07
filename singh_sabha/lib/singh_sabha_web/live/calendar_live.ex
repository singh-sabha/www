defmodule SinghSabhaWeb.CalendarLive do
  use SinghSabhaWeb, :live_view

  def mount(_params, _session, socket) do
    today = Date.utc_today()

    socket =
      socket
      |> assign(:view_mode, :month)
      |> assign(:current_date, today)
      |> assign(:selected_date, today)
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

  defp load_events(socket) do
    events = [
      %{
        id: 1,
        title: "Team Meeting",
        start: ~U[2026-01-15 10:00:00Z],
        end: ~U[2026-01-15 11:00:00Z]
      },
      %{id: 2, title: "Lunch", start: ~U[2026-01-15 12:00:00Z], end: ~U[2026-01-15 13:00:00Z]},
      %{id: 3, title: "Dinner", start: ~U[2026-01-15 17:00:00Z], end: ~U[2026-01-15 19:00:00Z]},
      %{
        id: 4,
        title: "Project Review",
        start: ~U[2026-01-16 14:00:00Z],
        end: ~U[2026-01-16 16:00:00Z]
      },
      %{
        id: 5,
        title: "Conference",
        start: ~U[2026-01-13 09:00:00Z],
        end: ~U[2026-01-15 17:00:00Z]
      },
      %{id: 6, title: "Vacation", start: ~U[2026-01-20 00:00:00Z], end: ~U[2026-01-25 23:59:59Z]}
    ]

    assign(socket, :events, events)
  end

  defp shift_date(date, :month, offset), do: Date.add(date, offset * 30)
  defp shift_date(date, :week, offset), do: Date.add(date, offset * 7)
  defp shift_date(date, :day, offset), do: Date.add(date, offset)

  defp period_label(date, :month), do: Calendar.strftime(date, "%B %Y")

  defp period_label(date, :week) do
    week_start = Date.beginning_of_week(date)
    week_end = Date.add(week_start, 6)
    "#{Calendar.strftime(week_start, "%b %d")} - #{Calendar.strftime(week_end, "%b %d, %Y")}"
  end

  defp period_label(date, :day), do: Calendar.strftime(date, "%A, %B %d, %Y")

  def render(assigns) do
    ~H"""
    <div class="p-2 ">
      <div class="flex justify-between p-4">
        <div class="space-x-4">
          <button phx-click="prev_period" class="btn btn-square">
            <.icon name="hero-chevron-left" />
          </button>

          <span class="text-sm text-base-400">
            {period_label(@current_date, @view_mode)}
          </span>

          <button phx-click="next_period" class="btn btn-square">
            <.icon name="hero-chevron-right" />
          </button>
        </div>
        <div class="join flex justify-end">
          <button class="btn join-item" phx-click="change_view" phx-value-view="month">Month</button>
          <button class="btn join-item" phx-click="change_view" phx-value-view="week">Week</button>
          <button class="btn join-item" phx-click="change_view" phx-value-view="day">Day</button>
        </div>
      </div>

      <%= if @view_mode == :month do %>
        <.month_view current_date={@current_date} events={@events} />
      <% end %>

      <%= if @view_mode == :week do %>
        <.week_view current_date={@current_date} events={@events} />
      <% end %>

      <%= if @view_mode == :day do %>
        <.day_view current_date={@current_date} events={@events} />
      <% end %>
    </div>
    """
  end

  defp month_view(assigns) do
    assigns = assign(assigns, :max_visible_events, 3)

    ~H"""
    <div>
      <div class="grid grid-cols-7 divide-x divide-base-300">
        <%= for day <- ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] do %>
          <div class="text-xs text-base-400 font-medium text-center py-2">{day}</div>
        <% end %>
      </div>

      <div class="grid grid-cols-7">
        <%= for date <- month_dates(@current_date) do %>
          <.day_cell
            date={date}
            current_date={@current_date}
            events={@events}
            max_visible_events={@max_visible_events}
          />
        <% end %>
      </div>
    </div>
    """
  end

  defp day_cell(assigns) do
    assigns =
      assigns
      |> assign(:is_saturday, Date.day_of_week(assigns.date) == 6)
      |> assign(:is_current_month, assigns.date.month == assigns.current_date.month)
      |> assign(:is_today, assigns.date == Date.utc_today())
      |> assign(:cell_events, events_for_date(assigns.events, assigns.date))

    ~H"""
    <div class={[
      "flex h-full flex-col gap-1 border-t border-base-300 py-1.5 lg:pb-2 lg:pt-1",
      !@is_saturday && "border-r"
    ]}>
      <button
        phx-click="select_date"
        phx-value-date={Date.to_iso8601(@date)}
        class={[
          "flex w-6 h-6 translate-x-1 items-center justify-center rounded-full text-xs font-semibold",
          "hover:bg-gray-100 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-500",
          "lg:px-2",
          !@is_current_month && "opacity-20",
          @is_today && "bg-blue-500 font-bold text-white hover:bg-blue-500"
        ]}
      >
        {@date.day}
      </button>

      <div class={[
        "flex h-6 gap-1 px-2 lg:h-[94px] lg:flex-col lg:gap-2 lg:px-0",
        !@is_current_month && "opacity-50"
      ]}>
        <%= for position <- 0..(@max_visible_events - 1) do %>
          <div class="lg:flex-1 lg:px-1">
            <%= if event = Enum.at(@cell_events, position) do %>
              <div class="w-2 h-2 rounded-full bg-blue-500 lg:hidden"></div>
              <div class="hidden lg:flex items-center gap-1.5 px-2 py-1 bg-blue-100 text-blue-800 rounded-md text-xs font-medium">
                <div class="flex w-full items-center justify-between">
                  <span class="truncate">{event.title}</span>
                  <span>{format_time(event.start)}</span>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if length(@cell_events) > @max_visible_events do %>
        <p class={[
          "h-4.5 px-1.5 text-xs font-semibold text-gray-500",
          !@is_current_month && "opacity-50"
        ]}>
          <span class="sm:hidden">+{length(@cell_events) - @max_visible_events}</span>
          <span class="hidden sm:inline">{length(@cell_events) - @max_visible_events} more...</span>
        </p>
      <% end %>
    </div>
    """
  end

  defp week_view(assigns) do
    ~H"""
    TODO week view {@current_date}
    """
  end

  defp day_view(assigns) do
    ~H"""
    TODO day view {@current_date}
    """
  end

  defp month_dates(date) do
    first_of_month = Date.beginning_of_month(date)
    last_of_month = Date.end_of_month(date)

    days_before_first = rem(Date.day_of_week(first_of_month), 7)
    first_display = Date.add(first_of_month, -days_before_first)

    days_after_last = rem(7 - Date.day_of_week(last_of_month), 7)
    last_display = Date.add(last_of_month, days_after_last)

    total_days = Date.diff(last_display, first_display)

    Enum.map(0..(total_days - 1), fn i -> Date.add(first_display, i) end)
  end

  defp events_for_date(events, date) do
    Enum.filter(events, fn event ->
      start_date = DateTime.to_date(event.start)
      end_date = DateTime.to_date(event.end)

      Date.compare(date, start_date) != :lt and Date.compare(date, end_date) != :gt
    end)
  end

  defp format_time(datetime) do
    hour = datetime.hour
    minute = String.pad_leading("#{datetime.minute}", 2, "0")
    period = if hour < 12, do: "AM", else: "PM"
    display_hour = if hour == 0, do: 12, else: if(hour > 12, do: hour - 12, else: hour)
    "#{display_hour}:#{minute} #{period}"
  end
end

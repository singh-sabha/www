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
    max_visible_events = 3
    {dates, first_display, last_display} = month_dates(assigns.current_date)

    event_positions =
      calculate_event_positions(
        assigns.events,
        first_display,
        last_display,
        max_visible_events
      )

    assigns =
      assigns
      |> assign(:dates, dates)
      |> assign(:event_positions, event_positions)
      |> assign(:max_visible_events, max_visible_events)

    ~H"""
    <div>
      <div class="grid grid-cols-7 divide-x divide-base-300">
        <%= for day <- ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] do %>
          <div class="text-xs text-base-400 font-medium text-center py-2">{day}</div>
        <% end %>
      </div>

      <div class="grid grid-cols-7">
        <%= for date <- @dates do %>
          <.day_cell
            date={date}
            current_date={@current_date}
            events={@events}
            event_positions={@event_positions}
            max_visible_events={@max_visible_events}
          />
        <% end %>
      </div>
    </div>
    """
  end

  defp day_cell(assigns) do
    {segments, overflow} =
      segments_for_date(
        assigns.events,
        assigns.event_positions,
        assigns.date
      )

    assigns =
      assigns
      |> assign(:saturday?, Date.day_of_week(assigns.date) == 6)
      |> assign(:current_month?, assigns.date.month == assigns.current_date.month)
      |> assign(:today?, assigns.date == Date.utc_today())
      |> assign(:segments, segments)
      |> assign(:overflow, overflow)

    ~H"""
    <div class={[
      "flex h-full flex-col gap-1 border-t border-base-300 py-1.5 lg:pb-2 lg:pt-1",
      !@saturday? && "border-r"
    ]}>
      <button
        phx-click="select_date"
        phx-value-date={Date.to_iso8601(@date)}
        class={[
          "flex w-6 h-6 translate-x-1 items-center justify-center rounded-full text-xs font-semibold",
          "hover:bg-gray-100 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-500",
          "lg:px-2",
          !@current_month? && "opacity-20",
          @today? && "bg-blue-500 font-bold text-white hover:bg-blue-500"
        ]}
      >
        {@date.day}
      </button>

      <div class={[
        "flex h-6 gap-1 px-2 lg:h-[94px] lg:flex-col lg:gap-2 lg:px-0",
        !@current_month? && "opacity-50"
      ]}>
        <%= for row <- 0..(@max_visible_events - 1) do %>
          <% segment = Enum.find(@segments, &(&1.row == row)) %>

          <div class={[
            "lg:flex-1",
            segment && segment.starts? && "lg:pl-1",
            segment && segment.ends? && "lg:pr-1"
          ]}>
            <%= if segment do %>
              <div class="w-2 h-2 rounded-full bg-blue-500 lg:hidden"></div>
              <div class={[
                "hidden lg:flex h-6.5 items-center bg-blue-100 text-blue-800 text-xs font-medium -mx-px",
                segment.starts? && "rounded-l-md ml-0",
                segment.ends? && "rounded-r-md mr-0",
                !segment.starts? && "rounded-l-none border-l-0",
                !segment.ends? && "rounded-r-none border-r-0"
              ]}>
                <%= if segment.starts? do %>
                  <div class="flex w-full items-center justify-between px-2 overflow-hidden whitespace-nowrap">
                    <span class="truncate">{segment.event.title}</span>
                    <span>{format_time(segment.event.start)}</span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @overflow > 0 do %>
        <p class={[
          "h-4.5 px-1.5 text-xs font-semibold text-gray-500",
          !@current_month? && "opacity-50"
        ]}>
          <span class="sm:hidden">+{@overflow}</span>
          <span class="hidden sm:inline">+{@overflow} more…</span>
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

    days =
      Enum.map(0..(total_days - 1), fn i ->
        Date.add(first_display, i)
      end)

    {days, first_display, last_display}
  end

  defp format_time(datetime) do
    hour = datetime.hour
    minute = String.pad_leading("#{datetime.minute}", 2, "0")
    period = if hour < 12, do: "AM", else: "PM"
    display_hour = if hour == 0, do: 12, else: if(hour > 12, do: hour - 12, else: hour)
    "#{display_hour}:#{minute} #{period}"
  end

  defp segments_for_date(events, event_positions, date) do
    active =
      Enum.filter(events, fn event ->
        start_date = DateTime.to_date(event.start)
        end_date = DateTime.to_date(event.end)

        Date.compare(date, start_date) != :lt and
          Date.compare(date, end_date) != :gt
      end)

    {visible, hidden} =
      Enum.split_with(active, fn event ->
        Map.has_key?(event_positions, event.id)
      end)

    segments =
      Enum.map(visible, fn event ->
        start_date = DateTime.to_date(event.start)
        end_date = DateTime.to_date(event.end)

        %{
          event: event,
          row: event_positions[event.id],
          starts?: date == start_date,
          ends?: date == end_date
        }
      end)

    {segments, length(hidden)}
  end

  defp calculate_event_positions(events, first_day, last_day, max_rows) do
    date_range =
      Date.range(first_day, last_day)
      |> Enum.to_list()

    occupied =
      Enum.reduce(date_range, %{}, fn day, acc ->
        Map.put(acc, day, List.duplicate(false, max_rows))
      end)

    sorted_events =
      Enum.sort(events, fn a, b ->
        Date.diff(DateTime.to_date(a.end), DateTime.to_date(a.start)) >=
          Date.diff(DateTime.to_date(b.end), DateTime.to_date(b.start))
      end)

    {positions, _} =
      Enum.reduce(sorted_events, {%{}, occupied}, fn event, {pos_acc, occ} ->
        event_days =
          Enum.filter(date_range, fn day ->
            Date.compare(day, DateTime.to_date(event.start)) != :lt and
              Date.compare(day, DateTime.to_date(event.end)) != :gt
          end)

        row =
          Enum.find(0..(max_rows - 1), fn i ->
            Enum.all?(event_days, fn day -> not Enum.at(occ[day], i) end)
          end)

        if row do
          new_occ =
            Enum.reduce(event_days, occ, fn day, acc ->
              Map.update!(acc, day, &List.replace_at(&1, row, true))
            end)

          {Map.put(pos_acc, event.id, row), new_occ}
        else
          {pos_acc, occ}
        end
      end)

    positions
  end
end

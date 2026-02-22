defmodule SinghSabhaWeb.CalendarLive.MonthView do
  use Phoenix.Component

  alias SinghSabhaWeb.Helpers.{
    EventTypeHelpers,
    TimezoneHelpers,
    UserHelpers
  }

  attr :current_date, :any, required: true
  attr :current_time, :any, required: true
  attr :current_scope, :map, default: nil
  attr :events, :list, required: true

  def view(assigns) do
    max_visible_events = 4
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
    <div class="border-t border-base-300 h-full flex flex-col">
      <div class="grid grid-cols-7 divide-x divide-base-300 shrink-0">
        <%= for day <- ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] do %>
          <div class="text-xs text-base-content/50 font-medium text-center py-2">{day}</div>
        <% end %>
      </div>

      <div class="grid grid-cols-7 flex-1 grid-rows-[repeat(auto-fit,minmax(0,1fr))]">
        <%= for date <- @dates do %>
          <.day_cell
            date={date}
            current_date={@current_date}
            current_time={@current_time}
            current_scope={@current_scope}
            events={@events}
            event_positions={@event_positions}
            max_visible_events={@max_visible_events}
          />
        <% end %>
      </div>
    </div>
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

  attr :date, :any, required: true
  attr :current_date, :any, required: true
  attr :current_time, :any, required: true
  attr :current_scope, :map, default: nil
  attr :events, :list, required: true
  attr :event_positions, :map, required: true
  attr :max_visible_events, :integer, required: true

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
      |> assign(:sunday?, Date.day_of_week(assigns.date) == 7)
      |> assign(:current_month?, assigns.date.month == assigns.current_date.month)
      |> assign(:today?, assigns.date == DateTime.to_date(assigns.current_time))
      |> assign(:segments, segments)
      |> assign(:overflow, overflow)

    ~H"""
    <div class={[
      "flex h-full flex-col border-t border-base-300 py-1.5 lg:py-1",
      !@saturday? && "border-r"
    ]}>
      <button
        phx-click="change_view_to_date"
        phx-value-date={Date.to_iso8601(@date)}
        class={[
          "flex w-6 h-6 translate-x-1 items-center justify-center rounded-full text-xs font-semibold shrink-0 mb-1 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-base-content/10 cursor-pointer",
          !@today? &&
            "hover:bg-base-content/10",
          !@current_month? && "opacity-20",
          @today? && "bg-primary text-primary-content"
        ]}
      >
        {@date.day}
      </button>

      <div class={[
        "flex flex-1 h-6 gap-1 px-2 lg:h-auto lg:flex-col lg:gap-2 lg:px-0",
        !@current_month? && "opacity-50"
      ]}>
        <%= for row <- 0..(@max_visible_events - 1) do %>
          <% segment = Enum.find(@segments, &(&1.row == row)) %>

          <%= if segment do %>
            <% colour = EventTypeHelpers.event_type_to_colour(segment.event.event_type.display_name) %>

            <div class={[
              "lg:flex-1",
              segment.starts? && "lg:pl-1",
              segment.ends? && "lg:pr-1"
            ]}>
              <div class={[
                "block w-2 h-2 rounded-full lg:hidden",
                EventTypeHelpers.dot_colour(colour)
              ]}>
              </div>
              <div
                class={[
                  "hidden lg:flex h-6.5 items-center text-xs font-medium border cursor-pointer",
                  EventTypeHelpers.badge_colour(colour),
                  UserHelpers.is_admin?(@current_scope) && segment.starts? &&
                    EventTypeHelpers.event_status_colour(
                      segment.event.is_verified,
                      segment.event.is_deposit_paid
                    ),
                  segment.starts? && "rounded-l-md",
                  segment.ends? && "rounded-r-md",
                  !segment.starts? && "rounded-l-none border-l-0",
                  !segment.ends? && "rounded-r-none border-r-0",
                  !@sunday? && "-ml-px",
                  !@saturday? && "-mr-px"
                ]}
                phx-click="view_event"
                phx-value-event-id={segment.event.id}
              >
                <%= if segment.starts? do %>
                  <div class="flex w-full items-center justify-between px-2 overflow-hidden whitespace-nowrap">
                    <span class="truncate">{segment.event.occassion}</span>
                    <span>{TimezoneHelpers.format_time(segment.event.start)}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% else %>
            <div class="lg:flex-1"></div>
          <% end %>
        <% end %>
      </div>

      <div class={[
        "flex items-center ml-1 shrink-0 h-4",
        !@current_month? && "opacity-50"
      ]}>
        <%= if @overflow > 0 do %>
          <p class="text-xs font-semibold text-base-content/50">
            <span class="sm:hidden">+{@overflow}</span>
            <span class="hidden sm:inline">+{@overflow} more…</span>
          </p>
        <% end %>
      </div>
    </div>
    """
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

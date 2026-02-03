defmodule SinghSabhaWeb.CalendarLive.Components.WeekViewMultiDayEventsRow do
  use Phoenix.Component

  alias SinghSabhaWeb.Helpers.{TimezoneHelpers, EventTypeHelpers}

  def row(assigns) do
    week_start = Date.beginning_of_week(assigns.current_date, :sunday)
    week_end = Date.end_of_week(assigns.current_date, :sunday)

    week_days =
      Enum.map(0..6, fn i ->
        Date.add(week_start, i)
      end)

    processed_events = process_events(assigns.multi_day_events, week_start, week_end)
    event_rows = create_event_rows(processed_events)
    has_events = length(processed_events) > 0

    assigns =
      assigns
      |> assign(:week_days, week_days)
      |> assign(:event_rows, event_rows)
      |> assign(:has_events, has_events)

    ~H"""
    <%= if @has_events do %>
      <div class="hidden overflow-hidden sm:flex">
        <div class="w-18 border-b border-base-300"></div>
        <div class="grid flex-1 grid-cols-7 border-b border-l border-base-300">
          <%= for {day, day_index} <- Enum.with_index(@week_days) do %>
            <div class="flex h-full flex-col gap-1 py-1 border-r border-base-300 last:border-r-0">
              <%= for {row, row_index} <- Enum.with_index(@event_rows) do %>
                <% event =
                  Enum.find(row, fn e -> e.start_index <= day_index and e.end_index >= day_index end) %>
                <%= if event do %>
                  <% starts = day_index == event.start_index %>
                  <% ends = day_index == event.end_index %>
                  <% colour =
                    EventTypeHelpers.event_type_to_colour(
                      event.original_event.event_type.display_name
                    ) %>

                  <.multi_day_event_badge
                    event={event.original_event}
                    colour={colour}
                    starts={starts}
                    ends={ends}
                  />
                <% else %>
                  <div class="h-6.5"></div>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp process_events(events, week_start, week_end) do
    events
    |> Enum.map(fn event ->
      start_date = DateTime.to_date(event.start)
      end_date = DateTime.to_date(event.end)

      adjusted_start =
        if Date.compare(start_date, week_start) == :lt, do: week_start, else: start_date

      adjusted_end = if Date.compare(end_date, week_end) == :gt, do: week_end, else: end_date

      start_index = Date.diff(adjusted_start, week_start)
      end_index = Date.diff(adjusted_end, week_start)

      %{
        original_event: event,
        adjusted_start: adjusted_start,
        adjusted_end: adjusted_end,
        start_index: start_index,
        end_index: end_index
      }
    end)
    |> Enum.sort(fn a, b ->
      case DateTime.compare(
             DateTime.new!(a.adjusted_start, ~T[00:00:00]),
             DateTime.new!(b.adjusted_start, ~T[00:00:00])
           ) do
        :lt ->
          true

        :gt ->
          false

        :eq ->
          span_a = a.end_index - a.start_index
          span_b = b.end_index - b.start_index
          span_b > span_a
      end
    end)
  end

  defp create_event_rows(processed_events) do
    Enum.reduce(processed_events, [], fn event, rows ->
      row_index =
        Enum.find_index(rows, fn row ->
          Enum.all?(row, fn e ->
            e.end_index < event.start_index or e.start_index > event.end_index
          end)
        end)

      case row_index do
        nil ->
          rows ++ [[event]]

        index ->
          List.update_at(rows, index, fn row -> row ++ [event] end)
      end
    end)
  end

  defp multi_day_event_badge(assigns) do
    ~H"""
    <div
      class={[
        "h-6.5 text-xs font-medium flex items-center border -mx-px cursor-pointer",
        EventTypeHelpers.badge_colour(@colour),
        (!@event.is_verified || !@event.is_deposit_paid) && @starts &&
          "bg-event-pending",
        @starts && "rounded-l-md ml-1",
        @ends && "rounded-r-md mr-1",
        !@starts && "rounded-l-none border-l-0",
        !@ends && "rounded-r-none border-r-0"
      ]}
      phx-click="view_event"
      phx-value-event-id={@event.id}
    >
      <%= if @starts do %>
        <div class="flex w-full items-center justify-between px-2 overflow-hidden whitespace-nowrap">
          <span class="truncate">{@event.occassion}</span>
          <span>{TimezoneHelpers.format_time(@event.start)}</span>
        </div>
      <% end %>
    </div>
    """
  end
end

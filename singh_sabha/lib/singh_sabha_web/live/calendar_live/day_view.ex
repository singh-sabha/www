defmodule SinghSabhaWeb.CalendarLive.DayView do
  use Phoenix.Component

  import SinghSabhaWeb.Helpers.CalendarHelpers
  alias SinghSabhaWeb.CalendarLive.Components.{DayViewMultiDayEventsRow, CalendarTimeline}

  def view(assigns) do
    {single_day_events, multi_day_events} = partition_events(assigns.events)

    day_events =
      single_day_events
      |> Enum.filter(fn event ->
        event_date = DateTime.to_date(event.start)
        Date.compare(event_date, assigns.current_date) == :eq
      end)

    grouped_events = group_overlapping_events(day_events)

    events_with_overlap_info =
      for {group, group_index} <- Enum.with_index(grouped_events),
          event <- group do
        overlapping_group_indices =
          grouped_events
          |> Enum.with_index()
          |> Enum.filter(fn {other_group, _other_index} ->
            Enum.any?(other_group, fn other_event ->
              events_overlap?(event, other_event)
            end)
          end)
          |> Enum.map(fn {_group, index} -> index end)

        {event, group_index, overlapping_group_indices}
      end

    hours = get_visible_hours(assigns.visible_hours, assigns.working_hours)

    assigns =
      assigns
      |> assign(:single_day_events, single_day_events)
      |> assign(:multi_day_events, multi_day_events)
      |> assign(:day_events, day_events)
      |> assign(:events_with_overlap_info, events_with_overlap_info)
      |> assign(:hours, hours)

    ~H"""
    <div class="flex flex-1 flex-col">
      <div>
        <DayViewMultiDayEventsRow.row
          current_date={@current_date}
          multi_day_events={@multi_day_events}
        />

        <div class="relative z-20 flex border-b border-base-300">
          <div class="w-18"></div>
          <span class="flex-1 border-l border-base-300 py-2 text-center text-xs font-medium text-base-400">
            {Calendar.strftime(@current_date, "%a")}
            <span class="ml-1 font-semibold text-base-content">
              {@current_date.day}
            </span>
          </span>
        </div>
      </div>

      <div class="overflow-auto max-h-[800px]">
        <div class="flex">
          <div class="relative w-18 flex-shrink-0">
            <%= for {hour, index} <- Enum.with_index(@hours) do %>
              <div class="relative h-[96px]">
                <%= if index != 0 do %>
                  <div class="absolute -top-3 right-2 flex h-6 items-center">
                    <span class="text-xs text-base-400">{format_hour(hour)}</span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="relative flex-1 border-l border-base-300">
            <div class="relative">
              <%= for {hour, index} <- Enum.with_index(@hours) do %>
                <% is_working = is_working_hour(@current_date, hour, @working_hours) %>
                <div class={["relative h-[96px]", !is_working && "bg-calendar-disabled-hour"]}>
                  <%= if index != 0 do %>
                    <div class="pointer-events-none absolute inset-x-0 top-0 border-b border-base-300">
                    </div>
                  <% end %>

                  <div class="pointer-events-none absolute inset-x-0 top-1/2 border-b border-dashed border-base-300">
                  </div>
                </div>
              <% end %>

              <%= for {event, group_index, overlapping_indices} <- @events_with_overlap_info do %>
                <% total_overlapping = length(overlapping_indices) %>
                <% relative_position = Enum.find_index(overlapping_indices, &(&1 == group_index)) %>
                <% style =
                  get_event_style(event, relative_position, total_overlapping, @hours) %>
                <div class="absolute p-1" style={style}>
                  <div class="h-full rounded-md bg-blue-100 text-blue-800 px-2 py-1 text-xs overflow-hidden">
                    <div class="font-medium truncate">{event.title}</div>
                    <div class="text-blue-800">
                      {format_time(event.start)} - {format_time(event.end)}
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <CalendarTimeline.view current_time={@current_time} hours={@hours} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule SinghSabhaWeb.CalendarLive.WeekView do
  use Phoenix.Component

  alias SinghSabhaWeb.Helpers.UserHelpers
  alias SinghSabhaWeb.CalendarLive.Components.{WeekViewMultiDayEventsRow, Timeline}
  alias SinghSabhaWeb.Helpers.{CalendarHelpers, TimezoneHelpers, EventTypeHelpers}

  def view(assigns) do
    week_start = Date.beginning_of_week(assigns.current_date, :sunday)

    week_days =
      Enum.map(0..6, fn i ->
        Date.add(week_start, i)
      end)

    {single_day_events, multi_day_events} = CalendarHelpers.partition_events(assigns.events)

    hours = CalendarHelpers.get_visible_hours(assigns.visible_hours, assigns.working_hours)

    assigns =
      assigns
      |> assign(:week_days, week_days)
      |> assign(:single_day_events, single_day_events)
      |> assign(:multi_day_events, multi_day_events)
      |> assign(:hours, hours)

    ~H"""
    <div class="flex flex-col items-center justify-center border-t border-base-300 py-4 text-sm text-base-400 sm:hidden">
      <p>Weekly view is not available on smaller devices.</p>
      <p>Please switch to daily or monthly view.</p>
    </div>

    <div class="hidden sm:flex flex-col border-t border-base-300 h-full">
      <div class="shrink-0">
        <WeekViewMultiDayEventsRow.row
          current_date={@current_date}
          current_scope={@current_scope}
          multi_day_events={@multi_day_events}
        />
        <div class="relative z-20 flex border-b border-base-300">
          <div class="w-18 flex-shrink-0"></div>
          <div class="grid flex-1 grid-cols-7 border-l border-base-300">
            <%= for day <- @week_days do %>
              <div class="py-2 text-center text-xs font-medium text-base-content/50 border-r border-base-300 last:border-r-0">
                {Calendar.strftime(day, "%a")}
                <span class="ml-1 font-semibold text-base-content">
                  {day.day}
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <div class="flex-1 min-h-0 overflow-auto hide-scrollbar">
        <div class="flex">
          <div class="relative w-18 flex-shrink-0">
            <%= for {hour, index} <- Enum.with_index(@hours) do %>
              <div class="relative h-[96px]">
                <%= if index != 0 do %>
                  <div class="absolute -top-3 right-2 flex h-6 items-center">
                    <span class="text-xs text-base-content/50">
                      {TimezoneHelpers.format_hour(hour)}
                    </span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="relative flex-1 border-l border-base-300">
            <div class="grid grid-cols-7">
              <%= for day <- @week_days do %>
                <.day_column
                  day={day}
                  hours={@hours}
                  events={@single_day_events}
                  working_hours={@working_hours}
                  current_scope={@current_scope}
                />
              <% end %>
            </div>

            <Timeline.view current_time={@current_time} hours={@hours} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp day_column(assigns) do
    day_events =
      assigns.events
      |> Enum.filter(fn event ->
        event_date = DateTime.to_date(event.start)
        Date.compare(event_date, assigns.day) == :eq
      end)

    grouped_events = CalendarHelpers.group_overlapping_events(day_events)

    events_with_overlap_info =
      for {group, group_index} <- Enum.with_index(grouped_events),
          event <- group do
        overlapping_group_indices =
          grouped_events
          |> Enum.with_index()
          |> Enum.filter(fn {other_group, _other_index} ->
            Enum.any?(other_group, fn other_event ->
              CalendarHelpers.events_overlap?(event, other_event)
            end)
          end)
          |> Enum.map(fn {_group, index} -> index end)

        {event, group_index, overlapping_group_indices}
      end

    assigns =
      assigns
      |> assign(:day_events, day_events)
      |> assign(:events_with_overlap_info, events_with_overlap_info)

    ~H"""
    <div class="relative border-r border-base-300 last:border-r-0">
      <%= for {hour, index} <- Enum.with_index(@hours) do %>
        <% is_working = CalendarHelpers.working_hour?(@day, hour, @working_hours) %>
        <div class={[
          "relative h-[96px]",
          !is_working && "bg-calendar-disabled-hour"
        ]}>
          <%= if index != 0 do %>
            <div class="pointer-events-none absolute inset-x-0 top-0 border-b border-base-300"></div>
          <% end %>

          <div
            class="absolute inset-x-0 top-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer"
            phx-click="create_event"
            phx-value-date={@day}
            phx-value-time={hour}
          >
          </div>

          <div class="pointer-events-none absolute inset-x-0 top-1/2 border-b border-dashed border-base-300">
          </div>

          <div
            class="absolute inset-x-0 bottom-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer"
            phx-click="create_event"
            phx-value-date={@day}
            phx-value-time={hour}
          >
          </div>
        </div>
      <% end %>

      <%= for {event, group_index, overlapping_indices} <- @events_with_overlap_info do %>
        <% total_overlapping = length(overlapping_indices) %>
        <% relative_position = Enum.find_index(overlapping_indices, &(&1 == group_index)) %>
        <% style =
          CalendarHelpers.get_event_style(event, relative_position, total_overlapping, @hours) %>

        <% colour = EventTypeHelpers.event_type_to_colour(event.event_type.display_name) %>

        <div class="absolute p-1 pointer-events-none" style={style}>
          <div
            class={[
              "h-full rounded-md border px-2 py-1 text-xs overflow-hidden cursor-pointer pointer-events-auto",
              UserHelpers.is_admin?(@current_scope) &&
                EventTypeHelpers.event_status_colour(event.is_verified, event.is_deposit_paid),
              EventTypeHelpers.badge_colour(colour)
            ]}
            phx-click="view_event"
            phx-value-event-id={event.id}
          >
            <div class="font-medium truncate">{event.occassion}</div>
            {TimezoneHelpers.format_time(event.start)} - {TimezoneHelpers.format_time(event.end)}
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end

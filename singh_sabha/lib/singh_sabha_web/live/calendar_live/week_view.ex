defmodule SinghSabhaWeb.CalendarLive.WeekView do
  use Phoenix.Component

  import SinghSabhaWeb.Helpers.CalendarHelpers

  def view(assigns) do
    week_start = Date.beginning_of_week(assigns.current_date, :sunday)

    week_days =
      Enum.map(0..6, fn i ->
        Date.add(week_start, i)
      end)

    {single_day_events, multi_day_events} = partition_events(assigns.events)

    hours = get_visible_hours(assigns.visible_hours, assigns.working_hours)

    assigns =
      assigns
      |> assign(:week_days, week_days)
      |> assign(:single_day_events, single_day_events)
      |> assign(:multi_day_events, multi_day_events)
      |> assign(:hours, hours)

    ~H"""
    <div class="flex flex-col items-center justify-center border-b border-base-300 py-4 text-sm text-base-400 sm:hidden">
      <p>Weekly view is not available on smaller devices.</p>
      <p>Please switch to daily or monthly view.</p>
    </div>

    <div class="hidden flex-col sm:flex">
      <div class="relative z-20 flex border-b border-base-300 pr-[15px]">
        <div class="w-18 flex-shrink-0"></div>
        <div class="grid flex-1 grid-cols-7 border-l border-base-300">
          <%= for day <- @week_days do %>
            <div class="py-2 text-center text-xs font-medium text-base-400 border-r border-base-300 last:border-r-0">
              {Calendar.strftime(day, "%a")}
              <span class="ml-1 font-semibold text-base-content">
                {day.day}
              </span>
            </div>
          <% end %>
        </div>
      </div>

      <div class="overflow-auto max-h-[736px]">
        <div class="flex overflow-hidden">
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
            <div class="grid grid-cols-7">
              <%= for day <- @week_days do %>
                <.day_column
                  day={day}
                  hours={@hours}
                  events={@single_day_events}
                  working_hours={@working_hours}
                />
              <% end %>
            </div>

            <.calendar_timeline current_time={@current_time} hours={@hours} />
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

    grouped_events = group_overlapping_events(day_events)

    assigns =
      assigns
      |> assign(:day_events, day_events)
      |> assign(:grouped_events, grouped_events)

    ~H"""
    <div class="relative border-r border-base-300 last:border-r-0">
      <%= for {hour, index} <- Enum.with_index(@hours) do %>
        <% is_working = is_working_hour(@day, hour, @working_hours) %>
        <div class={["relative h-[96px]", !is_working && "bg-calendar-disabled-hour"]}>
          <%= if index != 0 do %>
            <div class="pointer-events-none absolute inset-x-0 top-0 border-b border-base-300"></div>
          <% end %>

          <div class="pointer-events-none absolute inset-x-0 top-1/2 border-b border-dashed border-base-300">
          </div>
        </div>
      <% end %>

      <%= for {group, group_index} <- Enum.with_index(@grouped_events) do %>
        <%= for event <- group do %>
          <% style = get_event_style(event, @day, group_index, length(@grouped_events), @hours) %>
          <div class="absolute p-1" style={style}>
            <div class="h-full rounded-md bg-blue-100 text-blue-800 px-2 py-1 text-xs overflow-hidden">
              <div class="font-medium truncate">{event.title}</div>
              <div class="text-blue-800">
                {format_time(event.start)} - {format_time(event.end)}
              </div>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp calendar_timeline(assigns) do
    now = assigns.current_time
    current_hour = now.hour
    current_minute = now.minute

    hours_list = assigns.hours
    first_hour = List.first(hours_list)
    last_hour = List.last(hours_list)

    show_timeline = current_hour >= first_hour and current_hour <= last_hour

    if show_timeline do
      minutes = current_hour * 60 + current_minute
      visible_start_minutes = first_hour * 60
      visible_end_minutes = last_hour * 60
      visible_range_minutes = visible_end_minutes - visible_start_minutes
      position = (minutes - visible_start_minutes) / visible_range_minutes * 100

      time_string = format_time(now)

      assigns =
        assigns
        |> assign(:position, position)
        |> assign(:time_string, time_string)

      ~H"""
      <div
        class="pointer-events-none absolute inset-x-0 z-50 border-t border-black"
        style={"top: #{@position}%"}
      >
        <div class="absolute left-0 top-0 size-3 -translate-x-1/2 -translate-y-1/2 rounded-full bg-black">
        </div>
        <div class="absolute -left-18 flex w-16 -translate-y-1/2 justify-end bg-base-100 pr-1 text-xs font-medium text-black">
          {@time_string}
        </div>
      </div>
      """
    else
      ~H""
    end
  end
end

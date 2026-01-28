defmodule SinghSabhaWeb.CalendarLive.Components.CalendarTimeline do
  use Phoenix.Component

  alias SinghSabhaWeb.Helpers.CalendarHelpers

  def view(assigns) do
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
      visible_end_minutes = (last_hour + 1) * 60
      visible_range_minutes = visible_end_minutes - visible_start_minutes
      position = (minutes - visible_start_minutes) / visible_range_minutes * 100

      time_string = CalendarHelpers.format_time(now)

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

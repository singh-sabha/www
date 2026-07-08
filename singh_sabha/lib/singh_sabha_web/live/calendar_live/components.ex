defmodule SinghSabhaWeb.CalendarLive.Components do
  use Phoenix.Component

  alias SinghSabhaWeb.Helpers.Timezone

  attr :current_time, :any, required: true
  attr :hours, :list, required: true

  def timeline(assigns) do
    now = assigns.current_time
    current_hour = now.hour
    current_minute = now.minute

    hours_list = assigns.hours
    first_hour = List.first(hours_list)
    last_hour = List.last(hours_list)

    show? = current_hour >= first_hour and current_hour <= last_hour

    if show? do
      minutes = current_hour * 60 + current_minute
      visible_start_minutes = first_hour * 60
      visible_end_minutes = (last_hour + 1) * 60
      visible_range_minutes = visible_end_minutes - visible_start_minutes
      position = (minutes - visible_start_minutes) / visible_range_minutes * 100

      time_string = Timezone.format_time(now)

      assigns =
        assigns
        |> assign(:position, position)
        |> assign(:time_string, time_string)

      ~H"""
      <div
        class="pointer-events-none absolute inset-x-0 z-50 border-t border-black"
        style={"top: #{@position}%"}
      >
        <div class="absolute left-0 top-0 size-3 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary">
        </div>
        <div class="absolute -left-18 flex w-16 -translate-y-1/2 justify-end bg-base-100 pr-1 text-xs font-medium text-primary">
          {@time_string}
        </div>
      </div>
      """
    else
      ~H""
    end
  end

  def happening_now?(current_time, event_start_time, event_end_time) do
    DateTime.compare(current_time, event_start_time) in [:gt, :eq] &&
      DateTime.compare(current_time, event_end_time) == :lt
  end
end

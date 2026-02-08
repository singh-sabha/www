defmodule SinghSabhaWeb.CalendarLive.Components.DayViewMultiDayEventsRow do
  use Phoenix.Component

  alias SinghSabhaWeb.Helpers.CalendarHelpers
  alias SinghSabhaWeb.Helpers.{TimezoneHelpers, EventTypeHelpers}

  def row(assigns) do
    day_start = assigns.current_date
    day_end = assigns.current_date

    multi_day_events_in_day =
      assigns.multi_day_events
      |> Enum.filter(fn event ->
        event_start = DateTime.to_date(event.start)
        event_end = DateTime.to_date(event.end)

        Date.compare(event_end, day_start) != :lt and
          Date.compare(event_start, day_end) != :gt
      end)
      |> Enum.sort(fn a, b ->
        duration_a = Date.diff(DateTime.to_date(a.end), DateTime.to_date(a.start))
        duration_b = Date.diff(DateTime.to_date(b.end), DateTime.to_date(b.start))
        duration_b >= duration_a
      end)

    has_events = length(multi_day_events_in_day) > 0

    assigns =
      assigns
      |> assign(:multi_day_events_in_day, multi_day_events_in_day)
      |> assign(:has_events, has_events)

    ~H"""
    <%= if @has_events do %>
      <div class="flex border-b border-base-300">
        <div class="w-18"></div>
        <div class="flex flex-1 flex-col gap-1 border-l border-base-300 py-1 px-1">
          <%= for event <- @multi_day_events_in_day do %>
            <% event_start = DateTime.to_date(event.start) %>
            <% event_end = DateTime.to_date(event.end) %>
            <% event_total_days = Date.diff(event_end, event_start) + 1 %>
            <% event_current_day = Date.diff(@current_date, event_start) + 1 %>

            <.multi_day_event_badge
              event={event}
              event_current_day={event_current_day}
              event_total_days={event_total_days}
              current_scope={@current_scope}
            />
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp multi_day_event_badge(assigns) do
    ~H"""
    <% colour = EventTypeHelpers.event_type_to_colour(@event.event_type.display_name) %>

    <div class={[
      "flex h-6.5 items-center text-xs font-medium px-2 rounded-md border",
      CalendarHelpers.is_admin?(@current_scope) &&
        EventTypeHelpers.event_status_colour(@event.is_verified, @event.is_deposit_paid),
      EventTypeHelpers.badge_colour(colour)
    ]}>
      <div
        class="flex w-full items-center justify-between overflow-hidden whitespace-nowrap cursor-pointer"
        phx-click="view_event"
        phx-value-event-id={@event.id}
      >
        <span class="truncate">
          Day {@event_current_day} of {@event_total_days} • {@event.occassion}
        </span>
        <span class="ml-2">{TimezoneHelpers.format_time(@event.start)}</span>
      </div>
    </div>
    """
  end
end

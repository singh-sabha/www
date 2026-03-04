defmodule SinghSabhaWeb.CalendarLive.DayView do
  use Phoenix.Component
  use SinghSabhaWeb, :html

  alias SinghSabhaWeb.Helpers.{
    CalendarHelpers,
    TimezoneHelpers,
    EventTypeHelpers,
    UserHelpers
  }

  alias SinghSabhaWeb.CalendarLive.Components.{DayViewMultiDayEventsRow, Timeline}

  attr :current_date, :any, required: true
  attr :current_time, :any, required: true
  attr :current_scope, :map, default: nil
  attr :events, :list, required: true
  attr :working_hours, :map, required: true
  attr :visible_hours, :atom, required: true

  def view(assigns) do
    {single_day_events, multi_day_events} = CalendarHelpers.partition_events(assigns.events)

    day_events =
      single_day_events
      |> Enum.filter(fn event ->
        event_date = DateTime.to_date(event.start)
        Date.compare(event_date, assigns.current_date) == :eq
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

    hours = CalendarHelpers.get_visible_hours(assigns.visible_hours, assigns.working_hours)

    assigns =
      assigns
      |> assign(:single_day_events, single_day_events)
      |> assign(:multi_day_events, multi_day_events)
      |> assign(:day_events, day_events)
      |> assign(:events_with_overlap_info, events_with_overlap_info)
      |> assign(:hours, hours)

    ~H"""
    <div class="flex flex-row h-full">
      <div class="flex flex-1 flex-col border-t border-base-300">
        <div class="shrink-0">
          <DayViewMultiDayEventsRow.row
            current_date={@current_date}
            current_scope={@current_scope}
            multi_day_events={@multi_day_events}
          />

          <div class="relative z-20 flex border-b border-base-300">
            <div class="w-18"></div>
            <span class="flex-1 border-l border-base-300 py-2 text-center text-xs font-medium text-base-content/50">
              {Calendar.strftime(@current_date, "%a")}
              <span class="ml-1 font-semibold text-base-content">
                {@current_date.day}
              </span>
            </span>
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
              <div class="relative">
                <%= for {hour, index} <- Enum.with_index(@hours) do %>
                  <% is_working = CalendarHelpers.working_hour?(@current_date, hour, @working_hours) %>

                  <div class={["relative h-[96px]", !is_working && "bg-calendar-disabled-hour"]}>
                    <%= if index != 0 do %>
                      <div class="pointer-events-none absolute inset-x-0 top-0 border-b border-base-300">
                      </div>
                    <% end %>

                    <div
                      class="absolute inset-x-0 top-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer"
                      phx-click="create_event"
                      phx-value-date={@current_date}
                      phx-value-time={hour}
                    >
                    </div>

                    <div class="pointer-events-none absolute inset-x-0 top-1/2 border-b border-dashed border-base-300">
                    </div>

                    <div
                      class="absolute inset-x-0 bottom-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer"
                      phx-click="create_event"
                      phx-value-date={@current_date}
                      phx-value-time={hour + 0.5}
                    >
                    </div>
                  </div>
                <% end %>

                <%= for {event, group_index, overlapping_indices} <- @events_with_overlap_info do %>
                  <% total_overlapping = length(overlapping_indices) %>
                  <% relative_position = Enum.find_index(overlapping_indices, &(&1 == group_index)) %>
                  <% style =
                    CalendarHelpers.get_event_style(
                      event,
                      relative_position,
                      total_overlapping,
                      @hours
                    ) %>
                  <% colour = EventTypeHelpers.event_type_to_colour(event.event_type.display_name) %>
                  <div class="absolute p-1 pointer-events-none" style={style}>
                    <div
                      class={[
                        "h-full rounded-md border px-2 py-1 text-xs overflow-hidden cursor-pointer pointer-events-auto",
                        UserHelpers.is_privileged?(@current_scope) &&
                          EventTypeHelpers.event_status_colour(
                            event.is_verified,
                            event.is_deposit_paid
                          ),
                        EventTypeHelpers.badge_colour(colour)
                      ]}
                      phx-click="view_event"
                      phx-value-event-id={event.id}
                    >
                      <div class="font-medium truncate">{event.occassion}</div>
                      {TimezoneHelpers.format_time(event.start)} - {TimezoneHelpers.format_time(
                        event.end
                      )}
                    </div>
                  </div>
                <% end %>
              </div>

              <Timeline.view current_time={@current_time} hours={@hours} />
            </div>
          </div>
        </div>
      </div>

      <div class="hidden lg:block border-l border-t border-base-300 flex flex-col">
        <calendar-date
          id="day-view-mini-calendar"
          phx-hook=".CalendarDate"
          class="cally border-b border-base-300"
          first-day-of-week="0"
          show-outside-days="true"
          locale="en-CA"
          value={Date.to_iso8601(@current_date)}
        >
          <svg
            aria-label="Previous"
            slot="previous"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="size-6"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
          </svg>
          <svg
            aria-label="Next"
            slot="next"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="size-6"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
          <calendar-month></calendar-month>
        </calendar-date>

        <div class="p-2">
          <% current_events = happening_now(@current_time, @single_day_events) %>
          <%= if length(current_events) > 0 do %>
            <div class="flex items-start gap-2 px-4 pt-4">
              <div class="inline-grid *:[grid-area:1/1] mt-[5px]">
                <div class={["status animate-ping", EventTypeHelpers.dot_colour(:red)]}></div>
                <div class={["status", EventTypeHelpers.dot_colour(:red)]}></div>
              </div>
              <p class="text-sm font-semibold">Happening Now</p>
            </div>

            <div class="mt-3 px-4">
              <div class="space-y-6 pb-4">
                <%= for event <- current_events do %>
                  <div class="space-y-1.5">
                    <p class="line-clamp-2 text-sm font-semibold">{event.occassion}</p>

                    <div class="flex items-center gap-1.5 text-base-content/70">
                      <.icon name="hero-user" class="h-3.5 w-3.5" />
                      <span class="text-sm">
                        <%= if event.registrant_full_name && (UserHelpers.is_privileged?(@current_scope) or event.is_public) do %>
                          {event.registrant_full_name}
                        <% else %>
                          <span class="flex items-center gap-1">
                            <.icon name="hero-check-badge" class="h-3.5 w-3.5 bg-info" />
                            Gurdwara Singh Sabha
                          </span>
                        <% end %>
                      </span>
                    </div>

                    <div class="flex items-center gap-1.5 text-base-content/70">
                      <.icon name="hero-calendar" class="h-3.5 w-3.5" />
                      <span class="text-sm">{TimezoneHelpers.format_date(event.start)}</span>
                    </div>

                    <div class="flex items-center gap-1.5 text-base-content/70">
                      <.icon name="hero-clock" class="h-3.5 w-3.5" />
                      <span class="text-sm">
                        {TimezoneHelpers.format_time(event.start)} - {TimezoneHelpers.format_time(
                          event.end
                        )}
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% else %>
            <p class="p-4 text-center text-sm italic text-base-content/60">
              No events at the moment
            </p>
          <% end %>
        </div>
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".CalendarDate">
      export default {
        mounted() {
          this.el.addEventListener("change", (event) => {
            const selectedDate = event.target.value;
            this.pushEvent("date-selected", { date: selectedDate });
          });
        },
      };
    </script>
    """
  end

  defp happening_now(current_time, single_day_events) do
    Enum.reduce(single_day_events, [], fn event, acc ->
      if DateTime.compare(current_time, event.start) in [:gt, :eq] &&
           DateTime.compare(current_time, event.end) == :lt do
        [event | acc]
      else
        acc
      end
    end)
  end
end

defmodule SinghSabhaWeb.CalendarLive.Views.Day do
  use Phoenix.Component
  use SinghSabhaWeb, :html

  alias SinghSabhaWeb.Helpers.{
    Event,
    Timezone,
    EventType,
    User,
    Path,
    Colour
  }

  import SinghSabhaWeb.CalendarLive.Components

  attr :origin_path, :map, required: true
  attr :current_date, :any, required: true
  attr :current_time, :any, required: true
  attr :current_scope, :map, default: nil
  attr :events, :list, required: true
  attr :working_hours, :map, required: true
  attr :visible_hours, :atom, required: true

  def day(assigns) do
    {single_day_events, multi_day_events} = Event.partition_events(assigns.events)

    day_events =
      single_day_events
      |> Enum.filter(fn event ->
        event_date = DateTime.to_date(event.start)
        Date.compare(event_date, assigns.current_date) == :eq
      end)

    grouped_events = Event.group_overlapping_events(day_events)
    events_with_overlap_info = Event.get_overlap_info(grouped_events)

    hours = Event.get_visible_hours(assigns.visible_hours, assigns.working_hours)

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
          <.multiday_event_row
            current_date={@current_date}
            current_scope={@current_scope}
            multi_day_events={@multi_day_events}
            origin_path={@origin_path}
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
                        {Timezone.format_hour(hour)}
                      </span>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>

            <div class="relative flex-1 border-l border-base-300">
              <div class="relative">
                <%= for {hour, index} <- Enum.with_index(@hours) do %>
                  <% working? = Event.working_hour?(@current_date, hour, @working_hours) %>

                  <div class={["relative h-[96px]", !working? && "bg-calendar-disabled-hour"]}>
                    <%= if index != 0 do %>
                      <div class="pointer-events-none absolute inset-x-0 top-0 border-b border-base-300">
                      </div>
                    <% end %>

                    <.link patch={
                      Path.calendar(@origin_path,
                        action: :new,
                        date: @current_date,
                        time: hour
                      )
                    }>
                      <div class="absolute inset-x-0 top-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer">
                      </div>
                    </.link>

                    <div class="pointer-events-none absolute inset-x-0 top-1/2 border-b border-dashed border-base-300">
                    </div>

                    <.link patch={
                      Path.calendar(@origin_path,
                        action: :new,
                        date: @current_date,
                        time: hour + 0.5
                      )
                    }>
                      <div class="absolute inset-x-0 bottom-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer">
                      </div>
                    </.link>
                  </div>
                <% end %>

                <%= for {event, group_index, overlapping_indices} <- @events_with_overlap_info do %>
                  <% total_overlapping = length(overlapping_indices) %>
                  <% relative_position = Enum.find_index(overlapping_indices, &(&1 == group_index)) %>
                  <% style =
                    Event.get_event_style(
                      event,
                      relative_position,
                      total_overlapping,
                      @hours
                    ) %>
                  <% colour = EventType.event_type_to_colour(event.event_type.display_name) %>
                  <div class="absolute p-1 pointer-events-none" style={style}>
                    <.link patch={Path.calendar(@origin_path, action: {:show, event.id})}>
                      <div class={[
                        "h-full rounded-md border px-2 py-1 text-xs overflow-hidden cursor-pointer pointer-events-auto",
                        User.privileged?(@current_scope) &&
                          EventType.event_status_colour(
                            event.is_verified,
                            event.is_deposit_paid
                          ),
                        Colour.badge_colour(colour)
                      ]}>
                        <div class="font-medium truncate">{event.occasion}</div>
                        {Timezone.format_time(event.start)} - {Timezone.format_time(event.end)}
                      </div>
                    </.link>
                  </div>
                <% end %>
              </div>

              <.timeline current_time={@current_time} hours={@hours} />
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
          <% current_events = ongoing_events(@current_time, @single_day_events) %>
          <%= if length(current_events) > 0 do %>
            <div class="flex items-start gap-2 px-4 pt-4">
              <div class="inline-grid *:[grid-area:1/1] mt-[5px]">
                <div class={["status animate-ping", Colour.dot_colour(:red)]}></div>
                <div class={["status", Colour.dot_colour(:red)]}></div>
              </div>
              <p class="text-sm font-semibold">Happening Now</p>
            </div>

            <div class="mt-3 px-4">
              <div class="space-y-6 pb-4">
                <%= for event <- current_events do %>
                  <div class="space-y-1.5">
                    <p class="line-clamp-2 text-sm font-semibold">{event.occasion}</p>

                    <div class="flex items-center gap-1.5 text-base-content/70">
                      <.icon name="hero-user" class="h-3.5 w-3.5" />
                      <span class="text-sm">
                        <%= if event.registrant_full_name && (User.privileged?(@current_scope) or event.is_public) do %>
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
                      <span class="text-sm">{Timezone.format_date(event.start)}</span>
                    </div>

                    <div class="flex items-center gap-1.5 text-base-content/70">
                      <.icon name="hero-clock" class="h-3.5 w-3.5" />
                      <span class="text-sm">
                        {Timezone.format_time(event.start)} - {Timezone.format_time(event.end)}
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

  defp ongoing_events(current_time, single_day_events) do
    Enum.reduce(single_day_events, [], fn event, acc ->
      if Timezone.happening_now?(current_time, event.start, event.end) do
        [event | acc]
      else
        acc
      end
    end)
  end

  attr :origin_path, :map, required: true
  attr :current_date, :any, required: true
  attr :multi_day_events, :list, required: true
  attr :current_scope, :map, default: nil

  def multiday_event_row(assigns) do
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
            <% event_end = DateTime.to_date(event.end) %> <% event_total_days =
              Date.diff(event_end, event_start) + 1 %>
            <% event_current_day = Date.diff(@current_date, event_start) + 1 %>

            <.multiday_event_badge
              event={event}
              event_current_day={event_current_day}
              event_total_days={event_total_days}
              current_scope={@current_scope}
              origin_path={@origin_path}
            />
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  attr :origin_path, :map, required: true
  attr :event, :map, required: true
  attr :event_current_day, :integer, required: true
  attr :event_total_days, :integer, required: true
  attr :current_scope, :map, default: nil

  defp multiday_event_badge(assigns) do
    ~H"""
    <% colour = EventType.event_type_to_colour(@event.event_type.display_name) %>

    <.link patch={Path.calendar(@origin_path, action: {:show, @event.id})}>
      <div class={[
        "flex h-6.5 items-center text-xs font-medium px-2 rounded-md border",
        User.privileged?(@current_scope) &&
          EventType.event_status_colour(@event.is_verified, @event.is_deposit_paid),
        Colour.card_colour(colour)
      ]}>
        <div class="flex w-full items-center justify-between overflow-hidden whitespace-nowrap cursor-pointer">
          <span class="truncate">
            <span class="text-base-content/70 text-xs">
              Day {@event_current_day} of {@event_total_days} •
            </span>
            <span class={Colour.text_colour(colour)}>{@event.occasion}</span>
          </span>

          <span class={["ml-2", Colour.text_colour(colour)]}>
            {Timezone.format_time(@event.start)}
          </span>
        </div>
      </div>
    </.link>
    """
  end
end

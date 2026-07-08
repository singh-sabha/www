defmodule SinghSabhaWeb.CalendarLive.Views.Week do
  use Phoenix.Component
  use SinghSabhaWeb, :html

  import SinghSabhaWeb.CalendarLive.Components

  alias SinghSabhaWeb.Helpers.User

  alias SinghSabhaWeb.Helpers.{
    Event,
    Timezone,
    EventType
  }

  attr :current_date, :any, required: true
  attr :current_time, :any, required: true
  attr :current_scope, :map, default: nil
  attr :events, :list, required: true
  attr :working_hours, :map, required: true
  attr :visible_hours, :atom, required: true

  def week(assigns) do
    week_start = Date.beginning_of_week(assigns.current_date, :sunday)

    week_days =
      Enum.map(0..6, fn i ->
        Date.add(week_start, i)
      end)

    {single_day_events, multi_day_events} = Event.partition_events(assigns.events)

    hours = Event.get_visible_hours(assigns.visible_hours, assigns.working_hours)

    assigns =
      assigns
      |> assign(:week_days, week_days)
      |> assign(:single_day_events, single_day_events)
      |> assign(:multi_day_events, multi_day_events)
      |> assign(:hours, hours)

    ~H"""
    <div class="flex h-full flex-col items-center justify-center gap-2 border-t border-base-300 text-base-content/60 sm:hidden">
      <.icon name="hero-device-phone-mobile" class="size-10" />
      <p class="text-sm">Weekly view is not available on smaller devices.</p>
      <p class="text-sm">Please switch to daily or monthly view.</p>
    </div>

    <div class="hidden sm:flex flex-col border-t border-base-300 h-full">
      <div class="shrink-0">
        <.multiday_event_row
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
                      {Timezone.format_hour(hour)}
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

            <.timeline current_time={@current_time} hours={@hours} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :day, :any, required: true
  attr :hours, :list, required: true
  attr :events, :list, required: true
  attr :working_hours, :map, required: true
  attr :current_scope, :map, default: nil

  defp day_column(assigns) do
    day_events =
      assigns.events
      |> Enum.filter(fn event ->
        event_date = DateTime.to_date(event.start)
        Date.compare(event_date, assigns.day) == :eq
      end)

    grouped_events = Event.group_overlapping_events(day_events)
    events_with_overlap_info = Event.get_overlap_info(grouped_events)

    assigns =
      assigns
      |> assign(:day_events, day_events)
      |> assign(:events_with_overlap_info, events_with_overlap_info)

    ~H"""
    <div class="relative border-r border-base-300 last:border-r-0">
      <%= for {hour, index} <- Enum.with_index(@hours) do %>
        <% working? = Event.working_hour?(@day, hour, @working_hours) %>
        <div class={[
          "relative h-[96px]",
          !working? && "bg-calendar-disabled-hour"
        ]}>
          <%= if index != 0 do %>
            <div class="pointer-events-none absolute inset-x-0 top-0 border-b border-base-300"></div>
          <% end %>

          <div
            class="absolute inset-x-0 top-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer"
            phx-click="create_or_book_event"
            phx-value-date={@day}
            phx-value-time={hour}
          >
          </div>

          <div class="pointer-events-none absolute inset-x-0 top-1/2 border-b border-dashed border-base-300">
          </div>

          <div
            class="absolute inset-x-0 bottom-0 h-[48px] transition-colors hover:bg-base-content/10 cursor-pointer"
            phx-click="create_or_book_event"
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
          Event.get_event_style(event, relative_position, total_overlapping, @hours) %>

        <% colour = EventType.event_type_to_colour(event.event_type.display_name) %>

        <div class="absolute p-1 pointer-events-none" style={style}>
          <div
            class={[
              "h-full rounded-md border px-2 py-1 text-xs overflow-hidden cursor-pointer pointer-events-auto",
              User.privileged?(@current_scope) &&
                EventType.event_status_colour(event.is_verified, event.is_deposit_paid),
              EventType.badge_colour(colour)
            ]}
            phx-click="view_event"
            phx-value-event-id={event.id}
          >
            <div class="font-medium truncate">{event.occasion}</div>
            {Timezone.format_time(event.start)} - {Timezone.format_time(event.end)}
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :current_date, :any, required: true
  attr :multi_day_events, :list, required: true
  attr :current_scope, :map, default: nil

  defp multiday_event_row(assigns) do
    week_start = Date.beginning_of_week(assigns.current_date, :sunday)
    week_end = Date.end_of_week(assigns.current_date, :sunday)

    week_days =
      Enum.map(0..6, fn i ->
        Date.add(week_start, i)
      end)

    processed_events = process_events(assigns.multi_day_events, week_start, week_end)
    event_rows = generate_event_rows(processed_events)
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

                  <.multiday_event_badge
                    event={event.original_event}
                    starts={starts}
                    ends={ends}
                    current_scope={@current_scope}
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

  attr :event, :map, required: true
  attr :starts, :boolean, required: true
  attr :ends, :boolean, required: true
  attr :current_scope, :map, default: nil

  defp multiday_event_badge(assigns) do
    ~H"""
    <% colour = EventType.event_type_to_colour(@event.event_type.display_name) %>

    <div
      class={[
        "h-6.5 text-xs font-medium flex items-center border -mx-px cursor-pointer",
        EventType.badge_colour(colour),
        User.privileged?(@current_scope) && @starts &&
          EventType.event_status_colour(@event.is_verified, @event.is_deposit_paid),
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
          <span class="truncate">{@event.occasion}</span>
          <span>{Timezone.format_time(@event.start)}</span>
        </div>
      <% end %>
    </div>
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

  defp generate_event_rows(processed_events) do
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
end

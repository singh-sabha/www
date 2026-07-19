defmodule SinghSabhaWeb.CalendarLive.Views.Agenda do
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

  attr :current_date, :any, required: true
  attr :current_time, :any, required: true
  attr :current_scope, :map, default: nil
  attr :events, :list, required: true
  attr :origin_path, :map, required: true

  def agenda(assigns) do
    {single_day_events, multi_day_events} = Event.partition_events(assigns.events)

    events_by_day = group_events_by_day(single_day_events, multi_day_events, assigns.current_date)

    assigns =
      assigns
      |> assign(:events_by_day, events_by_day)

    ~H"""
    <div class="h-full overflow-auto">
      <div class="flex min-h-full flex-col p-4">
        <%= if length(@events_by_day) > 0 do %>
          <div class="space-y-6">
            <%= for day_group <- @events_by_day do %>
              <.day_group
                date={day_group.date}
                events={day_group.events}
                multi_day_events={day_group.multi_day_events}
                current_scope={@current_scope}
                origin_path={@origin_path}
              />
            <% end %>
          </div>
        <% else %>
          <div class="flex flex-1 flex-col items-center justify-center gap-2 text-base-content/60">
            <.icon name="hero-calendar-days" class="size-10" />
            <p class="text-sm md:text-base">No events scheduled for the selected month</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :date, :any, required: true
  attr :events, :list, required: true
  attr :multi_day_events, :list, required: true
  attr :current_scope, :any, required: true
  attr :origin_path, :map, required: true

  defp day_group(assigns) do
    sorted_events = Enum.sort_by(assigns.events, & &1.start, DateTime)

    assigns = assign(assigns, :sorted_events, sorted_events)

    ~H"""
    <div class="space-y-4">
      <div class="sticky top-0 flex items-center gap-4 bg-base-100 py-2 z-10">
        <p class="text-sm font-semibold">
          {Calendar.strftime(@date, "%A, %B %-d, %Y")}
        </p>
      </div>

      <div class="space-y-2">
        <%= for event <- @multi_day_events do %>
          <% event_start = DateTime.to_date(event.start) %>
          <% event_end = DateTime.to_date(event.end) %>
          <% current_date = @date %>
          <% event_total_days = Date.diff(event_end, event_start) + 1 %>
          <% event_current_day = Date.diff(current_date, event_start) + 1 %>

          <.event_card
            event={event}
            event_current_day={event_current_day}
            event_total_days={event_total_days}
            current_scope={@current_scope}
            origin_path={@origin_path}
          />
        <% end %>
        <%= for event <- @sorted_events do %>
          <.event_card
            event={event}
            current_scope={@current_scope}
            origin_path={@origin_path}
          />
        <% end %>
      </div>
    </div>
    """
  end

  attr :event, :map, required: true
  attr :event_current_day, :integer, default: nil
  attr :event_total_days, :integer, default: nil
  attr :current_scope, :any, required: true
  attr :origin_path, :map, required: true

  # TODO: could this be extracted into core_components? We're using a variation in AssistantLive
  defp event_card(assigns) do
    ~H"""
    <% colour = EventType.event_type_to_colour(@event.event_type.display_name) %>

    <.link patch={Path.calendar(@origin_path, action: {:show, @event.id})}>
      <div
        class={[
          "flex select-none items-center gap-3 rounded-md border p-3 text-sm transition-colors cursor-pointer",
          Colour.card_colour(colour),
          User.privileged?(@current_scope) &&
            EventType.event_status_colour(
              @event.is_verified,
              @event.is_deposit_paid
            )
        ]}
        role="button"
        tabindex="0"
      >
        <div class="flex flex-1 flex-col gap-2">
          <%= if User.privileged?(@current_scope) do %>
            <div class="mb-1 flex items-center gap-1.5">
              <%= cond do %>
                <% !@event.is_verified -> %>
                  <span class={[
                    "badge badge-sm gap-1",
                    Colour.badge_colour(:red)
                  ]}>
                    <.icon name="hero-exclamation-circle" class="size-3" /> Pending Approval
                  </span>
                <% @event.is_verified && !@event.is_deposit_paid -> %>
                  <span class={[
                    "badge badge-sm gap-1",
                    Colour.badge_colour(:yellow)
                  ]}>
                    <.icon name="hero-currency-dollar" class="size-3" /> Awaiting Payment
                  </span>
                <% true -> %>
                  <span class={[
                    "badge badge-sm gap-1",
                    Colour.badge_colour(:green)
                  ]}>
                    <.icon name="hero-check-circle" class="size-3" /> Confirmed
                  </span>
              <% end %>
            </div>
          <% end %>

          <div class="flex items-center gap-1.5">
            <p class="font-medium">
              <%= if @event_current_day && @event_total_days do %>
                <span class="mr-1 text-xs text-base-content/70">
                  Day {@event_current_day} of {@event_total_days} •
                </span>
              <% end %>
              <span class={Colour.text_colour(colour)}>
                {@event.occasion}
              </span>
            </p>
          </div>

          <div class="flex items-center gap-1.5">
            <.icon name="hero-user" class="size-3 shrink-0 text-base-content/70" />
            <p class="text-xs">
              <%= if @event.registrant_full_name && (User.privileged?(@current_scope) or @event.is_public) do %>
                {@event.registrant_full_name}
              <% else %>
                <span class="flex items-center gap-1">
                  <.icon name="hero-check-badge" class="size-3 bg-info" /> Gurdwara Singh Sabha
                </span>
              <% end %>
            </p>
          </div>

          <div class="flex items-center gap-1.5">
            <.icon name="hero-clock" class="size-3 shrink-0 text-base-content/70" />
            <p class="text-xs">
              {Timezone.format_time(@event.start)} - {Timezone.format_time(@event.end)}
            </p>
          </div>

          <div class="flex items-center gap-1.5">
            <.icon name="hero-tag" class="size-3 shrink-0 text-base-content/70" />
            <p class="text-xs">{@event.event_type.display_name}</p>
          </div>
        </div>
      </div>
    </.link>
    """
  end

  defp group_events_by_day(single_day_events, multi_day_events, current_date) do
    all_dates = %{}

    all_dates =
      Enum.reduce(single_day_events, all_dates, fn event, acc ->
        event_date = DateTime.to_date(event.start)

        if event_date.year == current_date.year && event_date.month == current_date.month do
          Map.update(
            acc,
            event_date,
            %{date: event_date, events: [event], multi_day_events: []},
            fn existing ->
              %{existing | events: [event | existing.events]}
            end
          )
        else
          acc
        end
      end)

    all_dates =
      Enum.reduce(multi_day_events, all_dates, fn event, acc ->
        event_start = DateTime.to_date(event.start)
        event_end = DateTime.to_date(event.end)

        event_start
        |> Date.range(event_end)
        |> Enum.reduce(acc, fn date, inner_acc ->
          if date.year == current_date.year && date.month == current_date.month do
            Map.update(
              inner_acc,
              date,
              %{date: date, events: [], multi_day_events: [event]},
              fn existing ->
                %{existing | multi_day_events: [event | existing.multi_day_events]}
              end
            )
          else
            inner_acc
          end
        end)
      end)

    all_dates
    |> Map.values()
    |> Enum.sort_by(& &1.date, Date)
  end
end

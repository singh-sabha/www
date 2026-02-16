defmodule SinghSabhaWeb.HomeLive.UpcomingEventsSection do
  use Phoenix.Component
  use SinghSabhaWeb, :html

  alias SinghSabhaWeb.Helpers.{TimezoneHelpers, EventTypeHelpers}

  attr :upcoming, :list, required: true
  attr :current_time, :any, required: true

  def section(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex justify-center items-center gap-2">
        <h3 class="text-lg font-semibold">Upcoming This Week</h3>
        <%= if length(@upcoming) > 0 do %>
          <span class="badge badge-primary">{length(@upcoming)} events</span>
        <% end %>
      </div>

      <%= if length(@upcoming) > 0 do %>
        <div
          class="carousel w-full rounded-box snap-x snap-mandatory overflow-x-hidden"
          phx-hook="AutoCarousel"
          id="auto-carousel"
        >
          <%= for {event, index} <- Enum.with_index(@upcoming) do %>
            <div
              id={"event-#{index}"}
              class="carousel-item w-full flex-shrink-0 snap-center justify-center"
            >
              <.event_card event={event} current_time={@current_time} />
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="flex flex-col items-center justify-center gap-2 rounded-box py-12">
          <.icon name="hero-calendar-days" class="size-10 opacity-50" />
          <p class="text-sm opacity-60">No upcoming events this week</p>
        </div>
      <% end %>
    </div>
    """
  end

  attr :event, :map, required: true
  attr :current_time, :any, required: true

  defp event_card(assigns) do
    colour = EventTypeHelpers.event_type_to_colour(assigns.event.event_type.display_name)

    days_until =
      Date.diff(DateTime.to_date(assigns.event.start), DateTime.to_date(assigns.current_time))

    time_label =
      cond do
        days_until == 0 -> "Today"
        days_until == 1 -> "Tomorrow"
        days_until <= 7 -> "In #{days_until} days"
        true -> Calendar.strftime(assigns.event.start, "%b %-d")
      end

    assigns =
      assigns
      |> assign(:colour, colour)
      |> assign(:time_label, time_label)

    ~H"""
    <div class={[
      "w-full max-w-md flex flex-col gap-3 rounded-md border p-4",
      EventTypeHelpers.card_colour(@colour)
    ]}>
      <div class="flex items-center justify-between">
        <div class={["badge badge-sm gap-1", EventTypeHelpers.badge_colour(@colour)]}>
          <.icon name="hero-clock" class="size-3" />
          {@time_label}
        </div>
      </div>

      <h4 class={[
        "font-semibold leading-tight line-clamp-2",
        EventTypeHelpers.text_colour(@colour)
      ]}>
        {@event.occassion}
      </h4>

      <div class="flex items-center gap-1.5">
        <.icon name="hero-tag" class="size-3 shrink-0 opacity-70" />
        <p class="text-xs">{@event.event_type.display_name}</p>
      </div>

      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar" class="size-3 shrink-0 opacity-70" />
        <p class="text-xs">{Calendar.strftime(@event.start, "%A, %B %-d, %Y")}</p>
      </div>

      <div class="flex items-center gap-1.5">
        <.icon name="hero-clock" class="size-3 shrink-0 opacity-70" />
        <p class="text-xs">
          {TimezoneHelpers.format_time(@event.start)} - {TimezoneHelpers.format_time(@event.end)}
        </p>
      </div>

      <%= if @event.note do %>
        <div class="flex items-start gap-1.5 mt-1">
          <.icon name="hero-document-text" class="size-3 shrink-0 opacity-70 mt-0.5" />
          <p class="text-xs opacity-70 line-clamp-2">{@event.note}</p>
        </div>
      <% end %>
    </div>
    """
  end
end

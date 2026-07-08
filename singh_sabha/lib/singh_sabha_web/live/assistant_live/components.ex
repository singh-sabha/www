defmodule SinghSabhaWeb.AssistantLive.Components do
  use Phoenix.Component

  import SinghSabhaWeb.CoreComponents

  alias SinghSabhaWeb.Helpers.{EventTypeHelpers, TimezoneHelpers}

  attr :event, :map, required: true
  attr :checked, :boolean, default: false
  attr :file_id, :any, required: true
  attr :event_id, :any, required: true

  def event_card(assigns) do
    ~H"""
    <% colour = EventTypeHelpers.event_type_to_colour(@event.event_type.display_name) %>

    <div class={[
      "flex select-none items-center gap-3 rounded-md border p-3 text-sm transition-colors",
      EventTypeHelpers.card_colour(colour)
    ]}>
      <input
        type="checkbox"
        class="checkbox checkbox-sm shrink-0"
        checked={@checked}
        phx-click="toggle_event_selection"
        phx-value-file-id={@file_id}
        phx-value-event-id={@event_id}
      />

      <div class="flex flex-1 flex-col gap-2 min-w-0">
        <div class="flex items-center gap-1.5">
          <p class="font-medium">
            <span class={EventTypeHelpers.text_colour(colour)}>
              {@event.occasion}
            </span>
          </p>
        </div>

        <div class="flex items-center gap-1.5">
          <.icon name="hero-clock" class="size-3 shrink-0 text-base-content/70" />
          <p class="text-xs">
            {TimezoneHelpers.format_datetime(@event.start)} - {TimezoneHelpers.format_datetime(
              @event.end
            )}
          </p>
        </div>

        <div class="flex items-center gap-1.5">
          <.icon name="hero-tag" class="size-3 shrink-0 text-base-content/70" />
          <p class="text-xs">{@event.event_type.display_name}</p>
        </div>

        <%= if @event.note do %>
          <div class="flex items-center gap-1.5">
            <.icon name="hero-document-text" class="size-3 shrink-0 text-base-content/70" />
            <p class="text-xs">{@event.note}</p>
          </div>
        <% end %>
      </div>

      <button
        type="button"
        class="btn btn-xs btn-ghost btn-circle shrink-0"
        phx-click="edit_event"
        phx-value-event-id={@event_id}
        phx-value-file-id={@file_id}
        aria-label="Edit event"
      >
        <.icon name="hero-pencil-square" class="size-4" />
      </button>
    </div>
    """
  end
end

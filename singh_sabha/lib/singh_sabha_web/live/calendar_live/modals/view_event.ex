defmodule SinghSabhaWeb.CalendarLive.Modals.ViewEvent do
  use SinghSabhaWeb, :live_component

  alias SinghSabhaWeb.Helpers.{
    EventType,
    Timezone,
    User
  }

  import SinghSabhaWeb.CalendarLive.Index, only: [calendar_path: 1, calendar_path: 2]

  attr :calendar_query, :map, required: true
  attr :id, :string, required: true
  attr :selected_event, :map, default: nil
  attr :current_scope, :map, default: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div class="modal-box">
      <button
        type="button"
        class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
        phx-click={JS.patch(calendar_path(@calendar_query))}
      >
        <.icon name="hero-x-mark" class="size-4" />
      </button>

      <h3 class="font-bold text-lg">{@selected_event.occasion}</h3>

      <div class="space-y-4 mt-4">
        <%= if @selected_event.is_verified && !@selected_event.is_deposit_paid do %>
          <div class={["mt-4 alert", EventType.badge_colour(:yellow)]}>
            <.icon name="hero-currency-dollar" class="size-5" />
            <span>
              Awaiting payment from organizer. Payment link sent to {@selected_event.registrant_email}
            </span>
          </div>
        <% end %>

        <div class="flex items-start gap-2">
          <.icon name="hero-user" class="mt-1 size-4 shrink-0" />
          <div>
            <p class="text-sm font-medium">Organizer</p>
            <p class="text-sm text-base-content/70">
              <%= if @selected_event.registrant_full_name && (User.privileged?(@current_scope) or @selected_event.is_public) do %>
                {@selected_event.registrant_full_name}
              <% else %>
                <span class="flex items-center gap-1">
                  <.icon name="hero-check-badge" class="size-4 bg-info" /> Gurdwara Singh Sabha
                </span>
              <% end %>
            </p>
          </div>
        </div>

        <div class="flex items-start gap-2">
          <.icon name="hero-tag" class="mt-1 size-4 shrink-0" />
          <div>
            <p class="text-sm font-medium">Event Type</p>
            <p class="text-sm text-base-content/70">
              {@selected_event.event_type.display_name}
            </p>
          </div>
        </div>

        <div class="flex items-start gap-2">
          <.icon name="hero-clock" class="mt-1 size-4 shrink-0" />
          <div>
            <p class="text-sm font-medium">Time</p>
            <p class="text-sm text-base-content/70">
              {Timezone.format_datetime(@selected_event.start)} - {Timezone.format_datetime(
                @selected_event.end
              )}
            </p>
          </div>
        </div>

        <%= if @selected_event.note do %>
          <div class="flex items-start gap-2">
            <.icon name="hero-document-text" class="mt-1 size-4 shrink-0" />
            <div>
              <p class="text-sm font-medium">Note</p>
              <p class="text-sm text-base-content/70">
                {@selected_event.note}
              </p>
            </div>
          </div>
        <% end %>

        <%= if User.privileged?(@current_scope) do %>
          <div class="modal-action">
            <%= if @selected_event.is_deposit_paid do %>
              <.link patch={calendar_path(@calendar_query, action: {:edit, @selected_event.id})}>
                <button
                  type="button"
                  class="btn"
                >
                  Edit
                </button>
              </.link>
              <button
                type="button"
                class="btn"
                phx-click="delete_event"
                phx-value-event-id={@selected_event.id}
              >
                Delete
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end

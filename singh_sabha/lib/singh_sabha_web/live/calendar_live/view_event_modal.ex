defmodule SinghSabhaWeb.CalendarLive.ViewEventModal do
  use SinghSabhaWeb, :live_component

  alias SinghSabhaWeb.Helpers.{CalendarHelpers, TimezoneHelpers}

  def render(assigns) do
    ~H"""
    <dialog
      id="view_event_modal"
      class="modal overflow-y-scroll"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box">
        <%= if @selected_event do %>
          <h3 class="font-bold text-lg">{@selected_event.occassion}</h3>

          <div class="space-y-4 mt-4">
            <%= if @selected_event.is_verified && !@selected_event.is_deposit_paid do %>
              <div class="alert alert-warning mt-4">
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
                  <%= if @selected_event.registrant_full_name && (CalendarHelpers.is_admin?(@current_scope) or @selected_event.is_public) do %>
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
                  {TimezoneHelpers.format_datetime(@selected_event.start)} - {TimezoneHelpers.format_datetime(
                    @selected_event.end
                  )}
                </p>
              </div>
            </div>

            <%= if @selected_event.note && CalendarHelpers.is_admin?(@current_scope) do %>
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

            <%= if CalendarHelpers.is_admin?(@current_scope) do %>
              <div class="modal-action">
                <%= if !@selected_event.is_verified do %>
                  <button
                    type="button"
                    class="btn btn-success"
                    phx-click="approve_event"
                    phx-value-event-id={@selected_event.id}
                  >
                    <span class="flex items-center gap-1">
                      <.icon name="hero-check-circle" class="size-4" /> Approve
                    </span>
                  </button>
                  <button
                    type="button"
                    class="btn btn-error"
                    phx-click="delete_event"
                    phx-value-event-id={@selected_event.id}
                  >
                    <span class="flex items-center gap-1">
                      <.icon name="hero-x-circle" class="size-4" /> Reject
                    </span>
                  </button>
                <% else %>
                  <%= if @selected_event.is_deposit_paid do %>
                    <button
                      type="button"
                      class="btn"
                      phx-click="edit_event"
                      phx-value-event-id={@selected_event.id}
                    >
                      <span class="flex items-center gap-1">
                        <.icon name="hero-pencil-square" class="size-4" /> Edit
                      </span>
                    </button>
                    <button
                      type="button"
                      class="btn btn-error"
                      phx-click="delete_event"
                      phx-value-event-id={@selected_event.id}
                    >
                      <span class="flex items-center gap-1">
                        <.icon name="hero-trash" class="size-4" /> Delete
                      </span>
                    </button>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          </div>
        <% else %>
          <p>No event selected</p>
        <% end %>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end

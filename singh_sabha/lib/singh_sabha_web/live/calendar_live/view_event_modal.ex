defmodule SinghSabhaWeb.CalendarLive.ViewEventModal do
  use SinghSabhaWeb, :live_component

  alias SinghSabhaWeb.Helpers.CalendarHelpers

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
              <.icon name="hero-calendar" class="mt-1 size-4 shrink-0" />
              <div>
                <p class="text-sm font-medium">Start Date</p>
                <p class="text-sm text-base-content/70">
                  {CalendarHelpers.format_datetime(@selected_event.start)}
                </p>
              </div>
            </div>

            <div class="flex items-start gap-2">
              <.icon name="hero-clock" class="mt-1 size-4 shrink-0" />
              <div>
                <p class="text-sm font-medium">End Date</p>
                <p class="text-sm text-base-content/70">
                  {CalendarHelpers.format_datetime(@selected_event.end)}
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

            <div class="modal-action">
              <button
                type="button"
                class="btn"
                phx-click="edit_event"
                phx-value-event-id={@selected_event.id}
              >
                Edit
              </button>

              <button
                type="button"
                class="btn btn-error"
                phx-click="delete_event"
                phx-value-event-id={@selected_event.id}
              >
                Delete
              </button>
            </div>
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

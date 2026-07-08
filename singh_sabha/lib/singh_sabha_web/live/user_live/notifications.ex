defmodule SinghSabhaWeb.UserLive.Notifications do
  alias SinghSabhaWeb.Helpers.Event
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events

  alias SinghSabha.Events.EventNotifier

  alias SinghSabhaWeb.Helpers.{User, EventType}

  alias SinghSabhaWeb.UsersLive.Modals.ReviewEvent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-2xl">
      <h1 class="text-xl font-semibold mb-6">Notifications</h1>

      <%= if length(@pending_events) == 0 do %>
        <div class="flex flex-col items-center justify-center gap-2 rounded-box pt-8">
          <.icon name="hero-bell-slash" class="size-10 text-base-content/70" />
          <p class="text-sm text-base-content/60">No pending notifications</p>
        </div>
      <% else %>
        <div class="space-y-3">
          <%= for event <- @pending_events do %>
            <% colour = EventType.event_type_to_colour(event.event_type.display_name) %>
            <div
              class={[
                "flex select-none items-center gap-3 rounded-md border p-3 text-sm transition-colors cursor-pointer",
                EventType.card_colour(colour)
              ]}
              phx-click="review_event"
              phx-value-event-id={event.id}
              role="button"
              tabindex="0"
            >
              <div class="flex flex-1 flex-col gap-2">
                <div class="flex items-center gap-1.5">
                  <span class={["badge badge-sm gap-1", EventType.badge_colour(:red)]}>
                    <.icon name="hero-exclamation-circle" class="size-3" /> Pending Approval
                  </span>
                </div>

                <div class="flex items-center gap-1.5">
                  <p class="font-medium">
                    <span class={EventType.text_colour(colour)}>
                      {event.occasion}
                    </span>
                  </p>
                </div>

                <div class="flex items-center gap-1.5">
                  <.icon name="hero-user" class="size-3 shrink-0 text-base-content/70" />
                  <p class="text-xs">{event.registrant_full_name}</p>
                </div>

                <div class="flex items-center gap-1.5">
                  <.icon name="hero-tag" class="size-3 shrink-0 text-base-content/70" />
                  <p class="text-xs">{event.event_type.display_name}</p>
                </div>
              </div>

              <.icon name="hero-chevron-right" class="size-4 text-base-content/40 shrink-0" />
            </div>
          <% end %>
        </div>
      <% end %>

      <.live_component
        :if={@selected_event}
        module={ReviewEvent}
        id="review_event_modal"
        selected_event={@selected_event}
        current_scope={@current_scope}
      />

      <div phx-hook="ModalManager" id="modal-manager"></div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")
    end

    socket =
      socket
      |> assign(:page_title, "Notifications")
      |> assign(:selected_event, nil)
      |> load_pending_events()

    {:ok, socket}
  end

  @impl true
  def handle_event("review_event", %{"event-id" => event_id}, socket) do
    event = Event.find_event(event_id, socket.assigns.pending_events)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> push_event("open-modal", %{id: "review_event_modal"})}
  end

  @impl true
  def handle_info({:approve_event, event_id, params}, socket) do
    event = Event.find_event(event_id, socket.assigns.pending_events)

    params =
      params
      |> Map.put("is_verified", true)

    case Events.update_event(event, params) do
      {:ok, updated_event} ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          "events",
          {:event_updated, updated_event}
        )

        EventNotifier.event_approved(updated_event)

        {:noreply,
         socket
         |> push_event("close-modal", %{id: "review_event_modal"})
         |> put_flash(:success, "Event approved successfully!")}

      {:error, _} ->
        {:noreply,
         socket
         |> push_event("close-modal", %{id: "review_event_modal"})
         |> put_flash(:error, "Could not approve event. Please try again later.")}
    end
  end

  def handle_info({:deny_event, event_id}, socket) do
    event = Event.find_event(event_id, socket.assigns.pending_events)

    case Events.delete_event(event) do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          "events",
          {:event_deleted, event}
        )

        EventNotifier.event_denied(event)

        {:noreply,
         socket
         |> push_event("close-modal", %{id: "review_event_modal"})
         |> put_flash(:success, "Event denied successfully!")}

      {:error, _} ->
        {:noreply,
         socket
         |> push_event("close-modal", %{id: "review_event_modal"})
         |> put_flash(:error, "Could not deny event. Please try again later.")}
    end
  end

  def handle_info({:event_created, _event}, socket) do
    {:noreply, load_pending_events(socket)}
  end

  def handle_info({:event_updated, _event}, socket) do
    {:noreply, load_pending_events(socket)}
  end

  def handle_info({:event_deleted, _event}, socket) do
    {:noreply, load_pending_events(socket)}
  end

  def handle_info({:put_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  defp load_pending_events(socket) do
    case User.privileged?(socket.assigns.current_scope) do
      true -> assign(socket, :pending_events, Events.list_events(:pending))
      false -> assign(socket, :pending_events, [])
    end
  end
end

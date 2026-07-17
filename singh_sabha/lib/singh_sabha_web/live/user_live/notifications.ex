defmodule SinghSabhaWeb.UserLive.Notifications do
  alias SinghSabhaWeb.Helpers.Event
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events
  alias SinghSabha.Events.EventNotifier
  alias SinghSabhaWeb.Helpers.{User, EventType, Timezone}
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
            <.link patch={~p"/users/notifications/#{event.id}"}>
              <div class={[
                "flex select-none items-center justify-between gap-3 rounded-md border p-3 text-sm transition-colors cursor-pointer",
                EventType.card_colour(colour)
              ]}>
                <div class="flex flex-col gap-1 min-w-0">
                  <p class="font-medium truncate">
                    <span class={EventType.text_colour(colour)}>{event.occasion}</span>
                  </p>
                  <p class="text-xs text-base-content/60 truncate">
                    {event.registrant_full_name} • {event.event_type.display_name}
                  </p>
                </div>
                <.icon name="hero-chevron-right" class="size-4 shrink-0 text-base-content/40" />
              </div>
            </.link>
          <% end %>
        </div>
      <% end %>

      <dialog :if={@live_action == :review} class="modal modal-open overflow-y-auto">
        <.live_component
          module={ReviewEvent}
          id="review_event_modal"
          selected_event={@selected_event}
          current_scope={@current_scope}
        />
      </dialog>
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
      |> load_pending_events()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :selected_event, nil)
  end

  defp apply_action(socket, :review, %{"id" => event_id}) do
    case Event.find_event(event_id, socket.assigns.pending_events) do
      nil ->
        socket
        |> put_flash(:error, "Notification not found.")
        |> push_patch(to: ~p"/users/notifications")

      event ->
        assign(socket, :selected_event, event)
    end
  end

  @impl true
  def handle_info({:approve_event, event_id, params}, socket) do
    event = Event.find_event(event_id, socket.assigns.pending_events)

    params =
      params
      |> Map.put("is_verified", true)
      |> Timezone.convert_datetime_params()

    case Events.update_event(event, params) do
      {:ok, updated_event} ->
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_updated, updated_event})
        EventNotifier.event_approved(updated_event)

        {:noreply,
         socket
         |> push_patch(to: ~p"/users/notifications")
         |> put_flash(:success, "Event approved successfully!")}

      {:error, _} ->
        {:noreply,
         socket
         |> push_patch(to: ~p"/users/notifications")
         |> put_flash(:error, "Could not approve event. Please try again later.")}
    end
  end

  def handle_info({:deny_event, event_id}, socket) do
    event = Event.find_event(event_id, socket.assigns.pending_events)

    case Events.delete_event(event) do
      {:ok, _} ->
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_deleted, event})
        EventNotifier.event_denied(event)

        {:noreply,
         socket
         |> push_patch(to: ~p"/users/notifications")
         |> put_flash(:success, "Event denied successfully!")}

      {:error, _} ->
        {:noreply,
         socket
         |> push_patch(to: ~p"/users/notifications")
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


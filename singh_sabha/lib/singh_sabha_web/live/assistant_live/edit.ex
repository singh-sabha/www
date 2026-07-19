defmodule SinghSabhaWeb.AssistantLive.Edit do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.Helpers.{EventType, Timezone, Path}
  alias SinghSabhaWeb.Components.Modals.EditEvent

  alias SinghSabha.Events
  alias SinghSabha.Events.Event
  alias SinghSabha.Drafts

  @impl true
  def mount(%{"draft_id" => draft_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")
    end

    case Drafts.get_draft(draft_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Draft not found.")
         |> push_navigate(to: ~p"/assistant")}

      draft ->
        {:ok, assign(socket, :draft, draft)}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:origin_path, %{draft_id: params["draft_id"]})

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("accept_event", %{"event-id" => event_id}, socket) do
    event = Enum.find(socket.assigns.draft.events, &(&1.id == String.to_integer(event_id)))

    case Events.update_event(event, %{"draft_id" => nil}) do
      {:ok, _updated} -> {:noreply, refresh_or_finish(socket)}
      {:error, _changeset} -> {:noreply, put_flash(socket, :error, "Could not accept event.")}
    end
  end

  def handle_event("deny_event", %{"event-id" => event_id}, socket) do
    event = Enum.find(socket.assigns.draft.events, &(&1.id == String.to_integer(event_id)))

    case Events.delete_event(event) do
      {:ok, _deleted} -> {:noreply, refresh_or_finish(socket)}
      {:error, _changeset} -> {:noreply, put_flash(socket, :error, "Could not deny event.")}
    end
  end

  @impl true
  def handle_info({:event_updated, updated_event}, socket) do
    draft = socket.assigns.draft

    updated_events =
      Enum.map(draft.events, fn
        %{id: id} when id == updated_event.id -> updated_event
        event -> event
      end)

    {:noreply, assign(socket, :draft, %{draft | events: updated_events})}
  end

  def handle_info({:put_flash, kind, msg}, socket) do
    {:noreply, put_flash(socket, kind, msg)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
  end

  defp apply_action(socket, :edit_event, %{"draft_id" => draft_id, "event_id" => event_id}) do
    with %Event{} = event <- Events.get_event(event_id),
         true <- event.draft_id == String.to_integer(draft_id) do
      assign(socket, :selected_event, event)
    else
      nil ->
        socket
        |> put_flash(:error, "Event not found.")
        |> push_navigate(to: ~p"/assistant/#{draft_id}/edit")

      false ->
        socket
        |> put_flash(:warning, "Event is not associated with this draft.")
        |> push_navigate(to: ~p"/assistant/#{draft_id}/edit")
    end
  end

  defp refresh_or_finish(socket) do
    draft = Drafts.get_draft(socket.assigns.draft.id)

    if draft.events == [] do
      Drafts.delete_draft(draft)

      socket
      |> put_flash(:success, "Draft complete.")
      |> push_navigate(to: ~p"/assistant")
    else
      assign(socket, :draft, draft)
    end
  end
end

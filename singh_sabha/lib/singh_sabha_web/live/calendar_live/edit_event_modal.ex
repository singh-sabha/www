defmodule SinghSabhaWeb.CalendarLive.EditEventModal do
  use SinghSabhaWeb, :live_component

  alias SinghSabha.Events.Event
  alias SinghSabha.Events

  def render(assigns) do
    ~H"""
    <dialog
      id="edit_event_modal"
      class="modal overflow-y-scroll"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box">
        <h3 class="font-bold text-lg">Edit Event</h3>
        <p class="text-base-content/70 text-sm">
          Make changes to the event parameters. Click save when you're done.
        </p>

        <%= if @form do %>
          <.form
            for={@form}
            phx-target={@myself}
            phx-change="validate_event"
            phx-submit="update_event"
            class="space-y-4 mt-4"
          >
            <.input
              field={@form[:occassion]}
              type="text"
              placeholder="Add the occassion"
              label="Occassion"
              required
            />

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-0">
              <.input
                field={@form[:start]}
                type="datetime-local"
                label="Start Time"
                required
              />

              <.input
                field={@form[:end]}
                type="datetime-local"
                label="End Time"
                required
              />
            </div>

            <.input
              field={@form[:type]}
              type="select"
              label="Select an event type"
              options={Enum.map(@event_types, &{&1.display_name, &1.id})}
              required
            />

            <.input
              field={@form[:note]}
              type="textarea"
              label="Notes"
              placeholder="Add any notes or requests, for example, requesting an evening or afternoon Langar"
              rows="4"
            />

            <.input
              field={@form[:is_public]}
              type="checkbox"
              label="Public event"
              class="checkbox"
            />

            <div class="modal-action">
              <button type="submit" class="btn btn-primary">Save Event</button>
              <button type="button" class="btn" onclick="edit_event_modal.close()">
                Cancel
              </button>
            </div>
          </.form>
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
    event = assigns.selected_event || %Event{}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:event_types, Events.list_event_types())
     |> assign(
       :form,
       to_form(
         Events.change_event(event),
         as: :edit_event
       )
     )}
  end

  def handle_event("validate_event", %{"edit_event" => params}, socket) do
    form =
      socket.assigns.selected_event
      |> Events.change_event(params)
      |> to_form(action: :validate, as: :edit_event)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("update_event", %{"edit_event" => params}, socket) do
    case Events.update_event(socket.assigns.selected_event, params) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          "events",
          {:event_updated, event}
        )

        {:noreply,
         socket
         |> put_flash(:success, "Event updated")
         |> push_event("close-modal", %{id: "edit_event_modal"})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(
           socket,
           form: to_form(changeset, as: :edit_event)
         )}
    end
  end
end

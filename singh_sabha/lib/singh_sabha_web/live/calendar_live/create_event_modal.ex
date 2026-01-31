defmodule SinghSabhaWeb.CalendarLive.CreateEventModal do
  alias SinghSabhaWeb.Helpers.TimezoneHelpers
  use SinghSabhaWeb, :live_component

  alias SinghSabha.Events.Event
  alias SinghSabha.Events

  def render(assigns) do
    ~H"""
    <dialog
      id="create_event_modal"
      class="modal overflow-y-scroll"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box">
        <h3 class="font-bold text-lg">Create Event</h3>
        <p class="text-base-content/70 text-sm">
          Fill out the form based on your request. Click submit when you're done.
        </p>

        <.form
          for={@form}
          phx-change="validate_event"
          phx-submit="create_event"
          phx-target={@myself}
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
            <button type="submit" class="btn btn-primary">Create Event</button>
            <button type="button" class="btn" onclick="create_event_modal.close()">
              Cancel
            </button>
          </div>
        </.form>
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
     |> assign(assigns)
     |> assign(
       form:
         to_form(
           Events.change_event(%Event{}),
           as: :create_event
         )
     )}
  end

  def handle_event("validate_event", %{"create_event" => params}, socket) do
    form =
      %Event{}
      |> Events.change_event(params)
      |> to_form(action: :validate, as: :create_event)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create_event", %{"create_event" => params}, socket) do
    updated_params = TimezoneHelpers.convert_datetime_params(params)

    case Events.create_event(updated_params) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          "events",
          {:event_created, event}
        )

        {:noreply,
         socket
         |> put_flash(:success, "Event created")
         |> push_event("close-modal", %{id: "create_event_modal"})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(
           socket,
           form: to_form(changeset, as: :create_event)
         )}
    end
  end
end

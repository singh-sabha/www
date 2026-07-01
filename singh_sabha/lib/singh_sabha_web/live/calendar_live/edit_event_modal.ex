defmodule SinghSabhaWeb.CalendarLive.EditEventModal do
  alias SinghSabhaWeb.Helpers.TimezoneHelpers
  use SinghSabhaWeb, :live_component

  alias SinghSabha.Events.Event
  alias SinghSabha.Events

  attr :id, :string, required: true
  attr :selected_event, :map, default: nil
  attr :source, :any, default: nil

  def render(assigns) do
    ~H"""
    <dialog
      id="edit_event_modal"
      class="modal overflow-y-scroll"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </form>

        <h3 class="font-bold text-lg">Edit Event</h3>
        <p class="text-base-content/70 text-sm">
          Make changes to the event parameters. Click save when you're done.
        </p>

        <.form
          for={@form}
          phx-target={@myself}
          phx-change="validate_event"
          phx-submit="update_event"
          class="space-y-4 mt-4"
        >
          <.input
            field={@form[:occasion]}
            type="text"
            placeholder="Add the occasion"
            label="Occasion"
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
            label="Type"
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
            <button type="button" class="btn" onclick="edit_event_modal.close()">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">Save changes</button>
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
    event = assigns.selected_event || %Event{}

    # every event's start/end is stored as UTC; the datetime-local input
    # needs local wall-clock time, so shift for display only. "selected_event"
    # (assigned below via assigns) stays UTC for changeset/DB writes
    form_event =
      case event do
        %{start: %DateTime{}, end: %DateTime{}} -> TimezoneHelpers.convert_event_to_local(event)
        _ -> event
      end

    source =
      case event do
        %{__meta__: %{state: :loaded}} -> {:db, nil}
        _ -> Map.get(assigns, :source, {:pending, nil, nil})
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:source, source)
     |> assign(:event_types, Events.list_event_types(:all))
     |> assign(
       :form,
       to_form(
         Events.change_event(form_event),
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
    updated_params = TimezoneHelpers.convert_datetime_params(params)

    case socket.assigns.source do
      {:db, _} ->
        case Events.update_event(socket.assigns.selected_event, updated_params) do
          {:ok, event} ->
            Phoenix.PubSub.broadcast(
              SinghSabha.PubSub,
              "events",
              {:event_updated, event}
            )

            send(self(), {:put_flash, :success, "Event updated!"})

            {:noreply, push_event(socket, "close-modal", %{id: "edit_event_modal"})}

          {:error, %Ecto.Changeset{} = changeset} ->
            send(self(), {:put_flash, :error, "Error when updating event. Please try again."})

            {:noreply,
             assign(
               socket,
               form: to_form(changeset, as: :edit_event)
             )}
        end

      {:pending, file_id, index} ->
        event_type =
          Enum.find(socket.assigns.event_types, fn event_type ->
            event_type.id == String.to_integer(updated_params["type"])
          end)

        changeset = Events.change_event(socket.assigns.selected_event, updated_params)

        if changeset.valid? do
          updated_event =
            changeset
            |> Ecto.Changeset.apply_changes()
            |> Map.put(:event_type, %{
              id: Integer.to_string(event_type.id),
              display_name: event_type.display_name
            })

          send(self(), {:pending_event_updated, file_id, index, updated_event})
          {:noreply, push_event(socket, "close-modal", %{id: "edit_event_modal"})}
        else
          {:noreply,
           assign(socket, form: to_form(%{changeset | action: :validate}, as: :edit_event))}
        end
    end
  end
end

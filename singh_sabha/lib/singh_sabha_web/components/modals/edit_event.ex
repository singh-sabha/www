defmodule SinghSabhaWeb.Components.Modals.EditEvent do
  alias SinghSabhaWeb.Helpers.Timezone
  use SinghSabhaWeb, :live_component

  alias SinghSabha.Events

  attr :origin_path, :string, required: true
  attr :id, :string, required: true
  attr :selected_event, :map, default: nil

  def render(assigns) do
    ~H"""
    <div class="modal-box max-w-xl">
      <.button
        type="button"
        class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
        phx-click={JS.patch(@origin_path)}
      >
        <.icon name="hero-x-mark" class="size-4" />
      </.button>

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
          <.input field={@form[:start]} type="datetime-local" label="Start Time" required />
          <.input field={@form[:end]} type="datetime-local" label="End Time" required />
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
        <.input field={@form[:is_public]} type="checkbox" label="Public event" class="checkbox" />

        <div class="modal-action">
          <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">Save</.button>
        </div>
      </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    event = assigns.selected_event
    form_event = Timezone.convert_event_to_local(event)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:event_types, Events.list_event_types(:all))
     |> assign(:form, to_form(Events.change_event(form_event), as: :edit_event))}
  end

  def handle_event("validate_event", %{"edit_event" => params}, socket) do
    form =
      socket.assigns.selected_event
      |> Events.change_event(params)
      |> to_form(action: :validate, as: :edit_event)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("update_event", %{"edit_event" => params}, socket) do
    updated_params = Timezone.convert_datetime_params(params)

    case Events.update_event(socket.assigns.selected_event, updated_params) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_updated, event})
        send(self(), {:put_flash, :success, "Event updated!"})
        {:noreply, push_patch(socket, to: socket.assigns.origin_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        send(self(), {:put_flash, :error, "Error when updating event. Please try again."})
        {:noreply, assign(socket, form: to_form(changeset, as: :edit_event))}
    end
  end
end

defmodule SinghSabhaWeb.Components.Modals.CreateEvent do
  use SinghSabhaWeb, :live_component

  alias SinghSabhaWeb.Helpers.Timezone
  alias SinghSabha.Events.{Event}
  alias SinghSabha.Events

  import SinghSabhaWeb.CalendarLive.Index, only: [calendar_path: 1]

  attr :calendar_query, :map, required: true
  attr :id, :string, required: true
  attr :event_types, :list, required: true
  attr :start_datetime, :string, default: nil
  attr :end_datetime, :string, default: nil

  def render(assigns) do
    ~H"""
    <div class="modal-box max-w-4xl">
      <button
        type="button"
        class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
        phx-click={JS.patch(calendar_path(@calendar_query))}
      >
        <.icon name="hero-x-mark" class="size-4" />
      </button>

      <h3 class="font-bold text-lg">
        Create Event
      </h3>
      <p class="text-base-content/70 text-sm">
        Fill out the form based on your request. Click submit when you're done.
      </p>
      <.form
        for={@form}
        phx-change="validate_event"
        phx-submit="create_event"
        phx-target={@myself}
        class="mt-4"
      >
        <div class="flex flex-col justify-between space-y-4">
          <div class="grid grid-cols-1 w-full">
            <.input
              field={@form[:occasion]}
              type="text"
              placeholder="Add the occasion"
              label="Occasion"
              required
            />

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
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
              prompt="Select an event type"
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
          </div>
        </div>

        <div class="modal-action">
          <.button phx-disable-with="Creating..." class="btn btn-primary">Create</.button>
        </div>
      </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    # This gets populated when a user clicks on a gutter in week/day views
    init_params =
      case Map.has_key?(assigns, :start_datetime) do
        true ->
          %{
            "start" => assigns.start_datetime,
            "end" => assigns.end_datetime
          }

        false ->
          %{}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       form:
         to_form(
           Events.change_event(%Event{}, init_params),
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
    updated_params =
      params
      |> Map.merge(%{"is_deposit_paid" => true, "is_verified" => true})
      |> Timezone.convert_datetime_params()

    case Events.create_event(updated_params) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_created, event})
        send(self(), {:put_flash, :success, "Event created successfully!"})

        {:noreply, push_patch(socket, to: calendar_path(socket.assigns.calendar_query))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :create_event))}
    end
  end
end

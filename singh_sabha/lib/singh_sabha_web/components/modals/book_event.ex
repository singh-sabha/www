defmodule SinghSabhaWeb.Components.Modals.BookEvent do
  use SinghSabhaWeb, :live_component

  alias SinghSabha.Events.{Event, EventNotifier}
  alias SinghSabha.Events

  import SinghSabhaWeb.CalendarLive.Index, only: [calendar_path: 1]

  attr :calendar_query, :map, required: true
  attr :id, :string, required: true
  attr :event_types, :list, required: true
  attr :requested_date, :string, default: nil

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
        Book Event
      </h3>
      <p class="text-base-content/70 text-sm">
        Fill out the form based on your request. Click submit when you're done.
      </p>
      <.form
        for={@form}
        phx-change="validate_event"
        phx-submit="book_event"
        phx-target={@myself}
        class="mt-4"
      >
        <div class="flex flex-col justify-between space-y-4 md:flex-row md:space-y-0 md:space-x-4">
          <div class="grid grid-cols-1 h-fit w-full md:w-1/3">
            <.input
              field={@form[:registrant_full_name]}
              type="text"
              placeholder="Add full name"
              label="Full Name"
              required
            />
            <.input
              field={@form[:registrant_email]}
              type="email"
              placeholder="Add email"
              label="Email"
              required
            />
            <.input
              field={@form[:registrant_phone_number]}
              type="text"
              placeholder="Add phone number"
              label="Phone Number"
              required
            />
          </div>

          <div class="divider my-0 mb-4 md:hidden"></div>
          <div class="divider divider-horizontal mx-0 mr-4 hidden md:flex"></div>

          <div class="grid grid-cols-1 w-full md:w-2/3">
            <.input
              field={@form[:occasion]}
              type="text"
              placeholder="Add the occasion"
              label="Occasion"
              required
            />

            <.input
              field={@form[:requested]}
              type="date"
              label="Date"
              required
            />

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
          <.button phx-disable-with="Booking..." class="btn btn-primary">Book</.button>
        </div>
      </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    # This gets populated when a user clicks on a gutter in week/day views
    init_params =
      case Map.fetch(assigns, :requested_date) do
        {:ok, date} -> %{"requested" => Date.to_iso8601(date)}
        :error -> %{}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       form:
         to_form(
           Events.change_event(%Event{}, init_params),
           as: :book_event
         )
     )}
  end

  def handle_event("validate_event", %{"book_event" => params}, socket) do
    form =
      %Event{}
      |> Events.guest_change_event(params)
      |> to_form(action: :validate, as: :book_event)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("book_event", %{"book_event" => params}, socket) do
    case Events.book_event(params) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          "events",
          {:event_created, event}
        )

        EventNotifier.event_confirmation(event)
        EventNotifier.admin_notification(event)

        send(
          self(),
          {:put_flash, :success,
           "Event booking submitted successfully! Please check your email for confirmation."}
        )

        {:noreply, push_patch(socket, to: calendar_path(socket.assigns.calendar_query))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :book_event))}
    end
  end
end

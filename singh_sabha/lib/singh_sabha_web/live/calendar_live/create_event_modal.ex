defmodule SinghSabhaWeb.CalendarLive.CreateEventModal do
  use SinghSabhaWeb, :live_component

  alias SinghSabhaWeb.Helpers.{CalendarHelpers, TimezoneHelpers}
  alias SinghSabha.Events.{Event, EventNotifier}
  alias SinghSabha.Events

  def render(assigns) do
    ~H"""
    <dialog
      id="create_event_modal"
      class="modal overflow-y-scroll"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box max-w-4xl">
        <h3 class="font-bold text-lg">
          {if CalendarHelpers.is_admin?(assigns), do: "Create Event", else: "Book Event"}
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
          <div class={[
            "flex flex-col justify-between space-y-4",
            !CalendarHelpers.is_admin?(assigns) && "md:flex-row md:space-y-0 md:space-x-4"
          ]}>
            <%= if !CalendarHelpers.is_admin?(assigns) do %>
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
            <% end %>

            <div class={[
              "grid grid-cols-1 w-full",
              !CalendarHelpers.is_admin?(assigns) && "md:w-2/3"
            ]}>
              <.input
                field={@form[:occassion]}
                type="text"
                placeholder="Add the occassion"
                label="Occassion"
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
            <button type="button" class="btn" onclick="create_event_modal.close()">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">
              {if CalendarHelpers.is_admin?(assigns), do: "Create Event", else: "Submit"}
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
      |> then(fn p ->
        if CalendarHelpers.is_admin?(socket.assigns) do
          Map.merge(p, %{"is_deposit_paid" => true, "is_verified" => true})
        else
          p
        end
      end)
      |> TimezoneHelpers.convert_datetime_params()

    case Events.create_event(updated_params) do
      {:ok, event} ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          "events",
          {:event_created, event}
        )

        unless CalendarHelpers.is_admin?(socket.assigns) do
          event
          |> EventNotifier.event_confirmation()
          |> EventNotifier.admin_notification()
        end

        success_message =
          if CalendarHelpers.is_admin?(socket.assigns) do
            "Event created successfully"
          else
            "Event booking submitted and confirmation email sent successfully!"
          end

        {:noreply,
         socket
         |> put_flash(:success, success_message)
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

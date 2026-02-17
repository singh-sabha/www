defmodule SinghSabhaWeb.CalendarLive.RejectEventModal do
  use SinghSabhaWeb, :live_component

  attr :id, :string, required: true
  attr :selected_event, :map, default: nil

  def render(assigns) do
    ~H"""
    <dialog
      id="reject_event_modal"
      class="modal overflow-y-scroll"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
        </form>

        <h3 class="font-bold text-lg">Reject Event</h3>
        <p class="text-base-content/70 text-sm">
          Enter an appropriate message for denying the event.
        </p>

        <.form for={@form} phx-submit="reject" phx-target={@myself} class="mt-4">
          <.input
            type="textarea"
            field={@form[:reason]}
            label="Reason"
            placeholder="Event would overlap with several others"
            required
            rows="4"
          />

          <div class="modal-action">
            <button type="button" class="btn" onclick="reject_event_modal.close()">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">
              Submit
            </button>
          </div>
        </.form>
      </div>
    </dialog>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(%{}, as: :reject_event))}
  end

  def handle_event("reject", %{"reject_event" => %{"reason" => reason}}, socket) do
    if String.length(String.trim(reason)) >= 20 do
      send(self(), {:reject_event, socket.assigns.selected_event, reason})
      {:noreply, socket}
    else
      form =
        to_form(
          %{"reason" => reason},
          as: :reject_event,
          errors: [reason: {"must be at least 20 characters", []}]
        )

      {:noreply, assign(socket, :form, form)}
    end
  end
end

defmodule SinghSabhaWeb.PaymentsLive.Index do
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events
  alias SinghSabhaWeb.Helpers.Colour
  alias Stripe.Checkout.Session

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  defp apply_status(socket, status) do
    title =
      case status do
        :success -> "Payment Successful"
        :confirm_cancel -> "Confirm Cancellation"
        :cancel -> "Booking Cancelled"
        :error -> "Payment Error"
      end

    socket
    |> assign(:status, status)
    |> assign(:page_title, title)
  end

  def handle_params(
        %{"status" => "success", "event_id" => event_id, "session_id" => session_id},
        _uri,
        socket
      ) do
    case Events.get_event(event_id) do
      nil ->
        {:noreply,
         socket
         |> apply_status(:error)
         |> assign(:error_message, "Event not found.")}

      event ->
        case Session.retrieve(session_id) do
          {:ok, %{payment_status: "paid", metadata: %{"event_id" => ^event_id}}} ->
            {:ok, event} = Events.update_event(event, %{is_deposit_paid: true})
            Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_updated, event})

            {:noreply,
             socket
             |> apply_status(:success)
             |> assign(:event, event)
             |> put_flash(:success, "Payment successful! Your event is confirmed.")}

          {:ok, %{payment_status: "paid"}} ->
            {:noreply,
             socket
             |> apply_status(:error)
             |> assign(:error_message, "This payment session does not match the booking.")}

          {:ok, _session} ->
            {:noreply,
             socket
             |> apply_status(:error)
             |> assign(:error_message, "Payment was not completed.")}

          {:error, _error} ->
            {:noreply,
             socket
             |> apply_status(:error)
             |> assign(:error_message, "Could not verify payment session.")}
        end
    end
  end

  def handle_params(
        %{"status" => "cancel", "event_id" => event_id, "session_id" => session_id},
        _uri,
        socket
      ) do
    case Events.get_event(event_id) do
      nil ->
        {:noreply,
         socket
         |> apply_status(:error)
         |> assign(:error_message, "Event not found.")}

      event ->
        case Session.retrieve(session_id) do
          {:ok, %{metadata: %{"event_id" => ^event_id}}} ->
            {:noreply,
             socket
             |> apply_status(:confirm_cancel)
             |> assign(:event, event)
             |> assign(:session_id, session_id)}

          {:ok, _session} ->
            {:noreply,
             socket
             |> apply_status(:error)
             |> assign(:error_message, "This payment session does not match the booking.")}

          {:error, _error} ->
            {:noreply,
             socket
             |> apply_status(:error)
             |> assign(:error_message, "Could not verify payment session.")}
        end
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> apply_status(:error)
     |> assign(:error_message, "Invalid payment link.")}
  end

  def handle_event("confirm_cancel", _params, socket) do
    {:ok, _} = Events.delete_event(socket.assigns.event)
    Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_deleted, socket.assigns.event})

    {:noreply,
     socket
     |> apply_status(:cancel)
     |> put_flash(:success, "Event booking cancelled.")}
  end

  def handle_event("keep_booking", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/calendar")}
  end

  def render(%{status: :success} = assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8 p-6 space-y-4">
      <div class={["alert", Colour.badge_colour(:green)]}>
        <.icon name="hero-check-circle" class="size-6" />
        <div>
          <h3 class="font-bold">Payment Successful!</h3>
          <p>Your event booking has been confirmed.</p>
        </div>
      </div>

      <div class="flex flex-col gap-3 rounded-md border border-base-300 p-4">
        <div class="flex items-center gap-2">
          <.icon name="hero-identification" class="size-4" />
          <h4 class="font-semibold">Booking Reference</h4>
        </div>
        <p class="text-sm text-base-content/60">
          Please save your event ID in case you need to contact us about your booking.
        </p>
        <div class="flex w-full gap-2">
          <input
            type="text"
            class="input input-sm flex-1 font-mono text-sm"
            value={@event.id}
            readonly
          />
          <button
            class="btn btn-square btn-sm"
            phx-click={JS.dispatch("phx:copy", detail: %{text: to_string(@event.id)})}
          >
            <.icon name="hero-clipboard" class="size-4 [[data-copied]_&]:hidden" />
            <.icon name="hero-check" class="size-4 hidden [[data-copied]_&]:block" />
          </button>
        </div>
        <p class="text-sm text-base-content/60">
          For any questions or changes, reach us at
          <a href="mailto:bookings@singhsabha.net" class="link link-primary font-medium">
            bookings@singhsabha.net
          </a>
        </p>
      </div>

      <.link navigate={~p"/calendar"} class="btn btn-primary">
        <.icon name="hero-arrow-left" /> Return to Calendar
      </.link>
    </div>
    """
  end

  def render(%{status: :confirm_cancel} = assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8 p-6 space-y-4">
      <div class={["alert", Colour.badge_colour(:yellow)]}>
        <.icon name="hero-exclamation-triangle" class="size-6" />
        <div>
          <h3 class="font-bold">Cancel this booking?</h3>
          <p>
            This will permanently remove "{@event.occasion}" from the calendar. This can't be undone.
          </p>
        </div>
      </div>

      <div class="flex gap-2">
        <button type="button" class="btn btn-error" phx-click="confirm_cancel">
          <.icon name="hero-trash" class="size-4" /> Cancel Booking
        </button>
        <button type="button" class="btn" phx-click="keep_booking">
          Keep Booking
        </button>
      </div>
    </div>
    """
  end

  def render(%{status: :cancel} = assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8 p-6 space-y-4">
      <div class={["alert", Colour.badge_colour(:red)]}>
        <.icon name="hero-information-circle" class="size-6" />
        <div>
          <h3 class="font-bold">Booking Cancelled</h3>
          <p>Your event booking has been cancelled and removed from the calendar.</p>
        </div>
      </div>

      <div class="flex flex-col gap-3 rounded-md border border-base-300 p-4">
        <div class="flex items-center gap-2">
          <.icon name="hero-exclamation-triangle" class="size-4" />
          <h4 class="font-semibold">Did you cancel by mistake?</h4>
        </div>
        <p class="text-sm text-base-content/70">
          Your booking has been permanently removed. If this was unintentional, you'll need to submit a new booking request from the calendar.
          If you need any assistance, reach us at
          <a href="mailto:bookings@singhsabha.net" class="link link-primary font-medium">
            bookings@singhsabha.net
          </a>
        </p>
      </div>

      <.link navigate={~p"/calendar"} class="btn btn-primary">
        <.icon name="hero-arrow-left" /> Return to Calendar
      </.link>
    </div>
    """
  end

  def render(%{status: :error} = assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8 p-6 space-y-4">
      <div class={["alert", Colour.badge_colour(:red)]}>
        <.icon name="hero-exclamation-circle" class="size-6" />
        <div>
          <h3 class="font-bold">Something Went Wrong</h3>
          <p>{@error_message}</p>
        </div>
      </div>

      <.link navigate={~p"/"} class="btn btn-primary">
        <.icon name="hero-arrow-left" /> Back to Home
      </.link>
    </div>
    """
  end
end

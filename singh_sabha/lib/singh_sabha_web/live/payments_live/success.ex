defmodule SinghSabhaWeb.PaymentsLive.Success do
  use SinghSabhaWeb, :live_view
  alias SinghSabha.Events
  alias SinghSabhaWeb.Helpers.EventTypeHelpers
  alias Stripe.Checkout.Session

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"event_id" => event_id, "session_id" => session_id}, _uri, socket) do
    case Events.get_event(event_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:warning, "Event not found.")
         |> push_navigate(to: ~p"/")}

      event ->
        case Session.retrieve(session_id) do
          {:ok, session} ->
            if session.payment_status == "paid" do
              {:ok, event} = Events.update_event(event, %{is_deposit_paid: true})

              Phoenix.PubSub.broadcast(
                SinghSabha.PubSub,
                "events",
                {:event_updated, event}
              )

              {:noreply,
               socket
               |> assign(:event, event)
               |> put_flash(:success, "Payment successful! Your event is confirmed.")}
            else
              {:noreply,
               socket
               |> put_flash(:warning, "Payment was not completed.")
               |> push_navigate(to: ~p"/")}
            end

          {:error, _error} ->
            {:noreply,
             socket
             |> put_flash(:error, "Could not verify payment session.")
             |> push_navigate(to: ~p"/")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto mt-8 p-6 space-y-4">
        <div class={["alert", EventTypeHelpers.badge_colour(:green)]}>
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
          <p class="text-sm opacity-60">
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
          <p class="text-sm opacity-60">
            For any questions or changes, reach us at
            <a href="mailto:singhsabhayyj@gmail.com" class="link link-primary font-medium">
              singhsabhayyj@gmail.com
            </a>
          </p>
        </div>

        <.link navigate={~p"/calendar"} class="btn btn-primary">
          <.icon name="hero-arrow-left" /> Return to Calendar
        </.link>
      </div>
    </Layouts.app>
    """
  end
end

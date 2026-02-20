defmodule SinghSabhaWeb.PaymentsLive.Success do
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events

  alias Stripe.Checkout.Session

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"event_id" => event_id, "session_id" => session_id}, _uri, socket) do
    case Events.get_event(event_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Event not found")
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
               |> put_flash(:error, "Payment was not completed")
               |> push_navigate(to: ~p"/")}
            end

          {:error, _error} ->
            {:noreply,
             socket
             |> put_flash(:error, "Could not verify payment session")
             |> push_navigate(to: ~p"/")}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto mt-8 p-6">
        <div class="alert alert-success">
          <.icon name="hero-check-circle" class="size-6" />
          <div>
            <h3 class="font-bold">Payment Successful!</h3>
            <p>Your event booking has been confirmed.</p>
          </div>
        </div>

        <div class="mt-6">
          <.link navigate={~p"/"} class="btn btn-primary">
            Return to Calendar
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

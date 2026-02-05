defmodule SinghSabhaWeb.PaymentsLive.Cancel do
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"event_id" => event_id}, _uri, socket) do
    case Events.get_event(event_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Event not found")
         |> push_navigate(to: ~p"/")}

      event ->
        {:ok, _} = Events.delete_event(event)

        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_deleted, event})

        {:noreply,
         socket
         |> assign(:event, event)
         |> put_flash(:info, "Event booking cancelled")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8 p-6">
      <div class="alert alert-info">
        <.icon name="hero-information-circle" class="size-6" />
        <div>
          <h3 class="font-bold">Booking Cancelled</h3>
          <p>Your event booking has been cancelled and removed from the calendar.</p>
        </div>
      </div>

      <div class="mt-6">
        <.link navigate={~p"/"} class="btn btn-primary">
          Return to Calendar
        </.link>
      </div>
    </div>
    """
  end
end

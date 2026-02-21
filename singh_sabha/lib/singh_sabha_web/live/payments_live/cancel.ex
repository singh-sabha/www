defmodule SinghSabhaWeb.PaymentsLive.Cancel do
  use SinghSabhaWeb, :live_view
  alias SinghSabha.Events
  alias SinghSabhaWeb.Helpers.EventTypeHelpers

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"event_id" => event_id}, _uri, socket) do
    case Events.get_event(event_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:warning, "Event not found.")}

      event ->
        {:ok, _} = Events.delete_event(event)
        Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_deleted, event})

        {:noreply,
         socket
         |> assign(:event, event)
         |> put_flash(:success, "Event booking cancelled.")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto mt-8 p-6 space-y-4">
        <div class={["alert", EventTypeHelpers.badge_colour(:red)]}>
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

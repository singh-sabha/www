defmodule SinghSabhaWeb.HomeLive.ServicesSection do
  use Phoenix.Component
  use SinghSabhaWeb, :html
  alias SinghSabhaWeb.Helpers.EventTypeHelpers

  attr :event_types, :list, required: true

  def section(assigns) do
    ~H"""
    <section class="space-y-4">
      <h3 class="text-lg font-semibold flex justify-center items-center">Our Services</h3>
      <p class="text-sm opacity-60 text-center">
        Explore or book any of the various services we offer.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 container mx-auto pt-8">
        <%= for event_type <- @event_types do %>
          <.event_type_card event_type={event_type} />
        <% end %>
      </div>
    </section>
    """
  end

  attr :event_type, :map, required: true

  defp event_type_card(assigns) do
    colour = EventTypeHelpers.event_type_to_colour(assigns.event_type.display_name)

    assigns = assign(assigns, :colour, colour)

    ~H"""
    <div
      class={[
        "flex flex-col gap-3 rounded-md border p-4 cursor-pointer",
        EventTypeHelpers.card_colour(@colour)
      ]}
      phx-click="create_event"
      phx-value-event-id={assigns.event_type.id}
    >
      <h4 class={[
        "font-semibold leading-tight",
        EventTypeHelpers.text_colour(@colour)
      ]}>
        {@event_type.display_name}
      </h4>

      <p class="text-sm opacity-80 leading-relaxed">
        {@event_type.description}
      </p>
    </div>
    """
  end
end

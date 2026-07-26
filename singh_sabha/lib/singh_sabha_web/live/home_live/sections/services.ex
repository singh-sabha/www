defmodule SinghSabhaWeb.HomeLive.Sections.Services do
  use Phoenix.Component
  use SinghSabhaWeb, :html

  alias SinghSabhaWeb.Helpers.{EventType, Colour}

  attr :event_types, :list, required: true
  attr :current_scope, :map, default: nil

  def section(assigns) do
    ~H"""
    <section class="space-y-4" id="services">
      <h3 class="text-lg font-semibold flex justify-center items-center">Our Services</h3>
      <p class="text-sm text-base-content/60 text-center">
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
  attr :current_scope, :map, default: nil

  defp event_type_card(assigns) do
    colour = EventType.event_type_to_colour(assigns.event_type.display_name)

    assigns = assign(assigns, :colour, colour)

    ~H"""
    <div class={[
      "flex flex-col gap-3 rounded-md border p-4",
      Colour.card_colour(@colour)
    ]}>
      <h4 class={[
        "font-semibold leading-tight",
        Colour.text_colour(@colour)
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

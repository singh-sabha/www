defmodule SinghSabhaWeb.GalleryLive do
  use SinghSabhaWeb, :live_view
  use SinghSabhaWeb, :html

  alias SinghSabhaWeb.GalleryLive.ViewImageModal

  @images "priv/static/images/construction/gurdwara_construction_*.jpeg"
          |> Path.wildcard()
          |> Enum.sort()
          |> Enum.with_index(1)
          |> Enum.map(fn {path, i} ->
            %{
              id: i,
              src: "/images/construction/#{Path.basename(path)}",
              alt: "Construction photo #{i}"
            }
          end)

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <h1 class="text-2xl font-bold">Gallery</h1>

        <div class="flex flex-col gap-3 rounded-md border border-base-300 p-4">
          <div class="flex items-center gap-2">
            <h2 class="font-semibold">Construction and Growth</h2>
            <span class="badge badge-sm lg:badge-md badge-primary text-xs lg:text-md">
              {length(@images)} photos
            </span>
          </div>
          <p class="text-sm text-base-content/70">
            A visual journey through the building of our Gurdwara: from the earliest foundations
            to the spaces where our sangat gathers today.
          </p>
        </div>

        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
          <div
            :for={image <- @images}
            class="overflow-hidden rounded-md border border-base-300 cursor-pointer"
            phx-click="select"
            phx-value-id={image.id}
          >
            <img
              src={image.src}
              alt={image.alt}
              loading="lazy"
              class="w-full h-40 object-cover"
              onerror="this.closest('.cursor-pointer').style.display='none'"
            />
          </div>
        </div>

        <.live_component
          :if={@selected_image}
          module={ViewImageModal}
          id="view_image_modal"
          image={@selected_image}
          total={length(@images)}
        />

        <div phx-hook="ModalManager" id="gallery-modal-manager"></div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Gallery")
     |> assign(:images, @images)
     |> assign(:selected_image, nil)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    image = Enum.find(socket.assigns.images, &(&1.id == String.to_integer(id)))

    {:noreply,
     socket
     |> assign(:selected_image, image)
     |> push_event("open-modal", %{id: "view_image_modal"})}
  end
end

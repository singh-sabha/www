defmodule SinghSabhaWeb.GalleryLive.Index do
  use SinghSabhaWeb, :live_view
  use SinghSabhaWeb, :html

  alias SinghSabhaWeb.Components.Modals.ViewImage

  # TODO: use S3
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
        <.link
          :for={image <- @images}
          patch={~p"/gallery/#{image.id}"}
          class="overflow-hidden rounded-md border border-base-300 cursor-pointer block"
        >
          <img
            src={image.src}
            alt={image.alt}
            loading="lazy"
            class="w-full h-40 object-cover"
            onerror="this.closest('a').style.display='none'"
          />
        </.link>
      </div>

      <dialog :if={@live_action == :show} class="modal modal-open">
        <.live_component
          module={ViewImage}
          id="view_image_modal"
          image={@selected_image}
          total={length(@images)}
        />
      </dialog>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Gallery")
     |> assign(:images, @images)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :selected_event, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case Integer.parse(id) do
      {int_id, ""} ->
        case Enum.find(socket.assigns.images, &(&1.id == int_id)) do
          nil ->
            socket
            |> put_flash(:error, "Image not found.")
            |> push_patch(to: ~p"/gallery")

          image ->
            assign(socket, :selected_image, image)
        end

      :error ->
        socket
        |> put_flash(:error, "Image not found.")
        |> push_patch(to: ~p"/gallery")
    end
  end
end

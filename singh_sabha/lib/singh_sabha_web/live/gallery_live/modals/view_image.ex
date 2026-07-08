defmodule SinghSabhaWeb.GalleryLive.Modal.ViewImage do
  use SinghSabhaWeb, :live_component

  attr :id, :string, required: true
  attr :image, :map, required: true
  attr :total, :integer, required: true

  def render(assigns) do
    ~H"""
    <dialog
      id="view_image_modal"
      class="modal overflow-y-scroll"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box max-w-4xl">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </form>

        <h3 class="font-bold text-lg">Construction and Growth</h3>
        <p class="text-sm text-base-content/70 tabular-nums">
          Photo {@image.id} of {@total}
        </p>

        <img
          src={@image.src}
          alt={@image.alt}
          class="w-full object-contain rounded-md mt-4"
        />
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end

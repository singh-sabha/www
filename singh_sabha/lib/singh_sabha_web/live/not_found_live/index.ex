defmodule SinghSabhaWeb.NotFoundLive.Index do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.Helpers.Colour

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8 p-6 space-y-4">
      <div class={["alert", Colour.badge_colour(:yellow)]}>
        <.icon name="hero-exclamation-triangle" class="size-6" />
        <div>
          <h3 class="font-bold">Page Not Found</h3>
          <p>The page you're looking for doesn't exist or may have been moved.</p>
        </div>
      </div>
      <.link navigate={~p"/"} class="btn btn-primary">
        <.icon name="hero-arrow-left" /> Back to Home
      </.link>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Not Found")}
  end
end

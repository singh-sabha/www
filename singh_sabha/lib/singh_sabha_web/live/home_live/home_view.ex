defmodule SinghSabhaWeb.HomeLive do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.HomeLive.HeroSection

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:full_width, true)}
  end

  def render(assigns) do
    ~H"""
    <HeroSection.section />
    """
  end
end

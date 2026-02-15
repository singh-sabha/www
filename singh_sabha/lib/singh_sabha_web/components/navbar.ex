defmodule SinghSabhaWeb.Components.Navbar do
  alias SinghSabhaWeb.Helpers.UserHelpers
  use Phoenix.Component
  use SinghSabhaWeb, :verified_routes

  import SinghSabhaWeb.CoreComponents
  import SinghSabhaWeb.Helpers.UserHelpers

  attr :current_scope, :any, required: true

  def navbar(assigns) do
    ~H"""
    <div class="navbar bg-base-100 border-b border-base-300 sticky top-0 z-50">
      <div class="navbar-start">
        <div class="dropdown">
          <div tabindex="0" role="button" class="btn btn-ghost btn-circle lg:hidden">
            <.icon name="hero-bars-3" />
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow"
          >
            <li><.link navigate={~p"/calendar"}>Calendar</.link></li>
            <li><.link navigate={~p"/about"}>About</.link></li>
          </ul>
        </div>
        <.link navigate={~p"/"} class="btn btn-ghost text-xl">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M18 22V2.8a.8.8 0 0 0-1.17-.71L5.45 7.78a.8.8 0 0 0 0 1.44L18 15.5" />
          </svg>
          Gurdwara Singh Sabha
        </.link>
      </div>
      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <li><.link navigate={~p"/calendar"}>Calendar</.link></li>
          <li><.link navigate={~p"/about"}>About</.link></li>
        </ul>
      </div>
      <div class="navbar-end">
        <%= if @current_scope do %>
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
              <div
                class="w-10 h-10 rounded-full flex items-center justify-center"
                style={"background: linear-gradient(135deg, #{UserHelpers.generate_gradient_colours(@current_scope.user.email)})"}
              >
              </div>
            </div>
            <ul
              tabindex="0"
              class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow"
            >
              <li class="menu-title">
                <span>{@current_scope.user.email}</span>
              </li>
              <li>
                <.link navigate={~p"/users/settings"}>Settings</.link>
              </li>
              <li>
                <.link href={~p"/users/log-out"} method="delete">Log out</.link>
              </li>
            </ul>
          </div>
        <% else %>
          <.link navigate={~p"/users/register"} class="btn btn-ghost btn-sm">Register</.link>
          <.link navigate={~p"/users/log-in"} class="btn btn-primary btn-sm">Log in</.link>
        <% end %>
      </div>
    </div>
    """
  end
end

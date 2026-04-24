defmodule SinghSabhaWeb.Router do
  use SinghSabhaWeb, :router

  import SinghSabhaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SinghSabhaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :webhooks do
    plug SinghSabha.Plugs.RequireSecret
  end

  scope "/", SinghSabhaWeb do
    pipe_through :browser

    live_session :full_width,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :mount_current_scope},
        {SinghSabhaWeb.Hooks.PresenceHook, :default},
        {SinghSabhaWeb.Live.Layouts, :full_width}
      ] do
      live "/", HomeLive
    end

    live_session :default,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :mount_current_scope},
        {SinghSabhaWeb.Hooks.PresenceHook, :default},
        {SinghSabhaWeb.Live.Layouts, :default}
      ] do
      live "/calendar", CalendarLive
      live "/about", AboutLive
      live "/gallery", GalleryLive
    end

    live_session :empty,
      on_mount: [
        {SinghSabhaWeb.Hooks.PresenceHook, :default},
        {SinghSabhaWeb.Live.Layouts, :empty}
      ] do
      live "/payment/success", PaymentsLive.Success
      live "/payment/cancel", PaymentsLive.Cancel
    end
  end

  scope "/api/v1", SinghSabhaWeb do
    pipe_through [:api, :webhooks]

    post "/events/generate", WorkflowController, :generate
    post "/events/create", WorkflowController, :create
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:singh_sabha, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SinghSabhaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SinghSabhaWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :require_authenticated},
        {SinghSabhaWeb.Hooks.PresenceHook, :default},
        {SinghSabhaWeb.Live.Layouts, :default}
      ] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", SinghSabhaWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :mount_current_scope},
        {SinghSabhaWeb.Live.Layouts, :empty}
      ] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/", SinghSabhaWeb do
    pipe_through :browser

    live_session :not_found,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :mount_current_scope},
        {SinghSabhaWeb.Live.Layouts, :empty}
      ] do
      live "/*path", NotFoundLive, :index
    end
  end
end

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

  scope "/", SinghSabhaWeb do
    pipe_through :browser

    live_session :full_width,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :mount_current_scope},
        {SinghSabhaWeb.Hooks.PresenceHook, :default},
        {SinghSabhaWeb.Live.Layouts, :full_width}
      ] do
      live "/", HomeLive.Index, :index
    end

    live_session :default,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :mount_current_scope},
        {SinghSabhaWeb.Hooks.PresenceHook, :default},
        {SinghSabhaWeb.Live.Layouts, :default}
      ] do
      live "/calendar", CalendarLive.Index, :index
      live "/calendar/new", CalendarLive.Index, :new
      live "/calendar/:id", CalendarLive.Index, :show
      live "/calendar/:id/edit", CalendarLive.Index, :edit

      live "/about", AboutLive.Index, :index
      live "/gallery", GalleryLive.Index, :index
      live "/gallery/:id", GalleryLive.Index, :show
    end

    live_session :require_privileged_user,
      on_mount: [
        {SinghSabhaWeb.UserAuth, :mount_current_scope},
        {SinghSabhaWeb.Hooks.PresenceHook, :default},
        {SinghSabhaWeb.UserAuth, :require_privileged_user},
        {SinghSabhaWeb.Live.Layouts, :default}
      ] do
      live "/assistant", AssistantLive.Index, :index
    end

    live_session :empty,
      on_mount: [
        {SinghSabhaWeb.Live.Layouts, :empty}
      ] do
      live "/payment/:status", PaymentsLive.Index, :index
    end
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

      live "/users/notifications", UserLive.Notifications, :index
      live "/users/notifications/:id", UserLive.Notifications, :review
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

defmodule SinghSabhaWeb.Live.Layouts do
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     assign(socket,
       page_layout: :default,
       show_navbar: true,
       show_footer: true,
       full_width: false
     )}
  end

  def on_mount(:empty, _params, _session, socket) do
    {:cont,
     assign(socket,
       page_layout: :empty,
       show_navbar: false,
       show_footer: false,
       full_width: false
     )}
  end

  def on_mount(:full_width, _params, _session, socket) do
    {:cont,
     assign(socket,
       page_layout: :full_width,
       show_navbar: true,
       show_footer: true,
       full_width: true
     )}
  end
end

defmodule SinghSabhaWeb.Hooks.PresenceHook do
  require Logger

  import Phoenix.LiveView

  alias SinghSabhaWeb.Presence
  alias SinghSabhaWeb.Helpers.User

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      ip = fetch_ip(socket)

      profile = build_profile(socket.assigns.current_scope, ip)

      Presence.track(self(), "global:presence", profile[:user_id], %{
        online_at: System.system_time(:second),
        user_id: profile[:user_id],
        display_name: profile[:display_name]
      })
    end

    {:cont, socket}
  end

  defp fetch_ip(socket) do
    peer_data = get_connect_info(socket, :peer_data)
    x_headers = get_connect_info(socket, :x_headers) || []

    case List.keyfind(x_headers, "x-forwarded-for", 0) do
      {_, ip} -> ip |> String.split(",") |> List.first() |> String.trim()
      nil when not is_nil(peer_data) -> peer_data.address |> Tuple.to_list() |> Enum.join(".")
      _ -> "unknown"
    end
  end

  defp build_profile(nil, ip) do
    encoding = Base.encode64(ip)

    [
      display_name: User.generate_guest_name(encoding),
      user_id: "guest:#{encoding}"
    ]
  end

  defp build_profile(user, _ip) do
    [
      display_name: user.user.full_name,
      user_id: "user:#{user.user.id}"
    ]
  end
end

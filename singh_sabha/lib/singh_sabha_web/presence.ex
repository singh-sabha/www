defmodule SinghSabhaWeb.Presence do
  use Phoenix.Presence,
    otp_app: :singh_sabha,
    pubsub_server: SinghSabha.PubSub
end

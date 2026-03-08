defmodule SinghSabhaWeb.PromEx.Plugins.ViewerPlugin do
  use PromEx.Plugin

  alias SinghSabhaWeb.Presence

  @impl true
  def polling_metrics(opts) do
    poll_rate = Keyword.get(opts, :poll_rate, 5_000)

    [
      Polling.build(
        :viewer_count_poller,
        poll_rate,
        {__MODULE__, :execute_viewer_poll, []},
        [
          last_value(
            [:singhsabha, :viewers, :live, :count],
            event_name: [:singhsabha, :viewers, :poll],
            description: "Number of currently live viewers",
            measurement: :count
          )
        ]
      )
    ]
  end

  def execute_viewer_poll do
    count =
      try do
        Presence.list("global:presence") |> map_size()
      rescue
        _ -> 0
      end

    :telemetry.execute([:singhsabha, :viewers, :poll], %{count: count}, %{})
  end
end

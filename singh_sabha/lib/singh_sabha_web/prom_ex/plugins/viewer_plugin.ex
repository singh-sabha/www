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
          ),
          last_value(
            [:singhsabha, :viewers, :live, :geo],
            event_name: [:singhsabha, :viewers, :poll, :geo],
            description: "Live viewers by geographic location",
            measurement: :count,
            tags: [:country, :city, :lat, :lon]
          )
        ]
      )
    ]
  end

  def execute_viewer_poll do
    presences =
      if Process.whereis(SinghSabhaWeb.Presence) do
        try do
          Presence.list("global:presence")
        rescue
          _ -> %{}
        end
      else
        %{}
      end

    :telemetry.execute([:singhsabha, :viewers, :poll], %{count: map_size(presences)}, %{})

    presences
    |> Enum.filter(fn {_id, %{metas: [meta | _]}} -> meta[:lat] && meta[:lon] end)
    |> Enum.group_by(fn {_id, %{metas: [meta | _]}} ->
      {meta[:country], meta[:city], meta[:lat], meta[:lon]}
    end)
    |> Enum.each(fn {{country, city, lat, lon}, viewers} ->
      :telemetry.execute(
        [:singhsabha, :viewers, :poll, :geo],
        %{count: length(viewers)},
        %{country: country, city: city, lat: lat, lon: lon}
      )
    end)
  end
end

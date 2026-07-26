defmodule SinghSabha.LiveStreamPoller do
  use GenServer
  require Logger

  alias SinghSabhaWeb.HomeLive.Sections.LiveStream

  # 10 minutes
  @interval 10 * 60 * 1000
  @table :live_stream_cache

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get_live_stream do
    case :ets.lookup(@table, :live_stream) do
      [{:live_stream, result}] -> result
      [] -> nil
    end
  end

  def init(_) do
    :ets.new(@table, [:named_table, :public, read_concurrency: true])
    send(self(), :refresh)
    {:ok, %{}}
  end

  def handle_info(:refresh, state) do
    if Mix.env() == :prod do
      case LiveStream.fetch_live_stream() do
        {:ok, result} ->
          :ets.insert(@table, {:live_stream, result})
          Logger.info("Youtube fetch successful!")

        {:error, reason} ->
          Logger.warning("YouTube fetch failed: #{inspect(reason)}")
      end
    else
      Logger.info("Skipping YouTube fetch due to runtime environment")
    end

    Process.send_after(self(), :refresh, @interval)
    {:noreply, state}
  end
end

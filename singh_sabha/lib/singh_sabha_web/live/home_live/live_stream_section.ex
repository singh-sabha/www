defmodule SinghSabhaWeb.HomeLive.LiveStreamSection do
  use Phoenix.Component
  use SinghSabhaWeb, :html

  @channel_id "UCtMxxM3Lr4qf8_EzrQORhQg"

  attr :live_stream, :map, default: nil

  def section(assigns) do
    ~H"""
    <section class="space-y-4">
      <div class="flex justify-center items-center gap-2">
        <%= if @live_stream do %>
          <span class="h-3 w-3 bg-red-500 rounded-full animate-pulse inline-block"></span>
          <h3 class="text-lg font-semibold">Currently Live</h3>
        <% else %>
          <h3 class="text-lg font-semibold">Live Stream</h3>
        <% end %>
      </div>
      <p class="text-sm opacity-60 text-center">
        Join us virtually for our live services and events.
      </p>

      <%= if @live_stream do %>
        <div class="pt-8">
          <.live_stream_card live_stream={@live_stream} />
        </div>
      <% else %>
        <div class="flex flex-col items-center justify-center gap-2 rounded-box pt-8">
          <.icon name="hero-video-camera-slash" class="size-10 opacity-70" />
          <p class="text-sm opacity-60">No live stream currently</p>
          <p class="text-sm">
            <span class="opacity-60">Visit our</span>
            <a
              href="https://www.youtube.com/@GurdwaraSinghSabhaVictoria"
              target="_blank"
              class="link link-primary inline-flex items-center gap-1"
            >
              YouTube channel <.icon name="hero-arrow-top-right-on-square" class="size-3" />
            </a>
            <span class="opacity-60">to watch past recordings.</span>
          </p>
        </div>
      <% end %>
    </section>
    """
  end

  attr :live_stream, :map, required: true

  defp live_stream_card(assigns) do
    ~H"""
    <div class="mx-auto overflow-hidden rounded-box border border-base-300">
      <div class="p-4 flex items-center justify-center">
        <p class="font-semibold">{@live_stream.title}</p>
      </div>
      <div class="aspect-video">
        <iframe
          class="w-full h-full"
          src={"https://www.youtube.com/embed/#{@live_stream.video_id}"}
          title={@live_stream.title}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          referrerpolicy="strict-origin-when-cross-origin"
          allowfullscreen
        >
        </iframe>
      </div>
    </div>
    """
  end

  def fetch_live_stream do
    youtube_api_key = Application.get_env(:singh_sabha, :youtube_api_key)

    case Req.get("https://www.googleapis.com/youtube/v3/search",
           params: %{
             part: "snippet",
             channelId: @channel_id,
             eventType: "live",
             type: "video",
             key: youtube_api_key
           }
         ) do
      {:ok, %Req.Response{status: 200, body: %{"items" => [live_stream | _]}}} ->
        {:ok,
         %{
           title: get_in(live_stream, ["snippet", "title"]),
           video_id: get_in(live_stream, ["id", "videoId"]),
           description: get_in(live_stream, ["snippet", "description"]),
           thumbnails: get_in(live_stream, ["snippet", "thumbnails"])
         }}

      {:ok, %Req.Response{status: 200, body: %{"items" => []}}} ->
        {:ok, nil}

      {:ok, %Req.Response{status: status}} ->
        {:error, "YouTube API returned status #{status}"}

      {:error, reason} ->
        {:error, "Failed to fetch live stream: #{inspect(reason)}"}
    end
  end
end

defmodule SinghSabhaWeb.HomeLive do
  alias SinghSabhaWeb.HomeLive.UpcomingEventsSection
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events
  alias SinghSabhaWeb.Helpers.TimezoneHelpers
  alias SinghSabhaWeb.HomeLive.HeroSection

  def render(assigns) do
    ~H"""
    <HeroSection.section />
    <div class="border-t border-base-300 border-b">
      <div class="container mx-auto px-4 py-8 border-t border-base-300">
        <UpcomingEventsSection.section
          upcoming={@upcoming}
          current_time={@current_time}
        />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    now = DateTime.now!(TimezoneHelpers.local())
    today = DateTime.to_date(now)
    week_start = Date.beginning_of_week(today, :sunday)
    week_end = Date.add(week_start, 6)

    if connected?(socket) do
      seconds_until_next_minute = 60 - now.second

      milliseconds_until_next_minute =
        seconds_until_next_minute * 1000 - rem(now.microsecond |> elem(0), 1000)

      Process.send_after(self(), :tick, milliseconds_until_next_minute)
    end

    upcoming =
      Events.list_events_between_dates(:public, today, week_end)
      |> Enum.map(fn event ->
        %{
          event
          | start: TimezoneHelpers.utc_to_local(event.start),
            end: TimezoneHelpers.utc_to_local(event.end)
        }
      end)

    {:ok,
     socket
     |> assign(:current_time, now)
     |> assign(:upcoming, upcoming)}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 30_000)

    {:noreply, assign(socket, :current_time, DateTime.now!(TimezoneHelpers.local()))}
  end
end

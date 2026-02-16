defmodule SinghSabhaWeb.HomeLive do
  alias SinghSabhaWeb.HomeLive.UpcomingEventsSection
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events
  alias SinghSabhaWeb.Helpers.TimezoneHelpers
  alias SinghSabhaWeb.HomeLive.HeroSection

  def mount(_params, _session, socket) do
    now = DateTime.now!(TimezoneHelpers.local())
    today = DateTime.to_date(now)
    week_start = Date.beginning_of_week(today, :sunday)
    week_end = Date.add(week_start, 6)

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

  def render(assigns) do
    ~H"""
    <HeroSection.section />
    <div class="container mx-auto px-4 py-8">
      <UpcomingEventsSection.section
        upcoming={@upcoming}
        current_time={@current_time}
      />
    </div>
    """
  end
end

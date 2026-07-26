defmodule SinghSabhaWeb.HomeLive.Index do
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events
  alias SinghSabhaWeb.Helpers.Timezone

  alias SinghSabhaWeb.HomeLive.Sections.{
    UpcomingEvents,
    Hero,
    Services,
    LiveStream,
    Donations
  }

  def render(assigns) do
    ~H"""
    <Hero.section />

    <.section_wrapper>
      <Services.section event_types={@event_types} current_scope={@current_scope} />
    </.section_wrapper>
    <.section_wrapper>
      <UpcomingEvents.section upcoming={@upcoming} current_time={@current_time} />
    </.section_wrapper>
    <.section_wrapper>
      <LiveStream.section live_stream={@live_stream} />
    </.section_wrapper>
    <.section_wrapper>
      <Donations.section />
    </.section_wrapper>
    """
  end

  def mount(_params, _session, socket) do
    now = DateTime.now!(Timezone.local())

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")
      Process.send_after(self(), :tick, Timezone.schedule_next_tick(now))
    end

    live_stream = SinghSabha.LiveStreamPoller.get_live_stream()

    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:current_time, now)
      |> assign(:live_stream, live_stream)
      |> assign(:event_types, Events.list_event_types(:public))
      |> upcoming_events()

    {:ok, socket}
  end

  slot :inner_block, required: true

  defp section_wrapper(assigns) do
    ~H"""
    <div class="border-t border-base-300">
      <div class="container mx-auto px-4 py-8">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 30_000)

    {:noreply, assign(socket, :current_time, DateTime.now!(Timezone.local()))}
  end

  def handle_info({:event_created, _event}, socket) do
    {:noreply, upcoming_events(socket)}
  end

  def handle_info({:event_updated, _event}, socket) do
    {:noreply, upcoming_events(socket)}
  end

  def handle_info({:event_deleted, _event}, socket) do
    {:noreply, upcoming_events(socket)}
  end

  def handle_info({:put_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  defp upcoming_events(socket) do
    today = DateTime.to_date(socket.assigns.current_time)

    week_start = Date.beginning_of_week(today, :sunday)
    week_end = Date.add(week_start, 6)

    upcoming =
      Events.list_events_between_dates(:public, today, week_end)
      |> Enum.map(fn event ->
        %{
          event
          | start: Timezone.utc_to_local(event.start),
            end: Timezone.utc_to_local(event.end)
        }
      end)

    assign(socket, :upcoming, upcoming)
  end
end

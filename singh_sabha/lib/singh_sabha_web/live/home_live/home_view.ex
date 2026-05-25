defmodule SinghSabhaWeb.HomeLive do
  use SinghSabhaWeb, :live_view

  alias SinghSabha.Events
  alias SinghSabhaWeb.Helpers.{TimezoneHelpers, UserHelpers}

  alias SinghSabhaWeb.HomeLive.{
    UpcomingEventsSection,
    HeroSection,
    ServicesSection,
    LiveStreamSection,
    DonationsSection
  }

  alias SinghSabhaWeb.CalendarLive.{CreateEventModal, BookEventModal}

  def render(assigns) do
    ~H"""
    <HeroSection.section />

    <.section_wrapper>
      <ServicesSection.section event_types={@event_types} current_scope={@current_scope} />
    </.section_wrapper>
    <.section_wrapper>
      <UpcomingEventsSection.section upcoming={@upcoming} current_time={@current_time} />
    </.section_wrapper>
    <.section_wrapper>
      <LiveStreamSection.section live_stream={@live_stream} />
    </.section_wrapper>
    <.section_wrapper>
      <DonationsSection.section />
    </.section_wrapper>

    <.live_component
      :if={UserHelpers.is_privileged?(@current_scope)}
      module={CreateEventModal}
      id="create_event_modal"
      event_types={
        if Map.has_key?(assigns, :selected_event_type),
          do: [@selected_event_type],
          else: @event_types
      }
    />
    <.live_component
      :if={!UserHelpers.is_privileged?(@current_scope)}
      module={BookEventModal}
      id="book_event_modal"
      event_types={
        if Map.has_key?(assigns, :selected_event_type),
          do: [@selected_event_type],
          else: @event_types
      }
    />

    <div phx-hook="ModalManager" id="modal-manager"></div>
    """
  end

  def mount(_params, _session, socket) do
    now = DateTime.now!(TimezoneHelpers.local())

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "events")

      seconds_until_next_minute = 60 - now.second

      milliseconds_until_next_minute =
        seconds_until_next_minute * 1000 - rem(now.microsecond |> elem(0), 1000)

      Process.send_after(self(), :tick, milliseconds_until_next_minute)
    end

    live_stream = SinghSabha.LiveStreamPoller.get_live_stream()

    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:current_time, now)
      |> assign(:live_stream, live_stream)
      |> load_upcoming_events()
      |> load_event_types()

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

    {:noreply, assign(socket, :current_time, DateTime.now!(TimezoneHelpers.local()))}
  end

  def handle_info({:event_created, _event}, socket) do
    {:noreply, load_upcoming_events(socket)}
  end

  def handle_info({:event_updated, _event}, socket) do
    {:noreply, load_upcoming_events(socket)}
  end

  def handle_info({:event_deleted, _event}, socket) do
    {:noreply, load_upcoming_events(socket)}
  end

  def handle_info({:put_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  def handle_event("create_or_book_event", %{"event-id" => event_id}, socket) do
    event_type = Enum.find(socket.assigns.event_types, &(&1.id == String.to_integer(event_id)))

    modal_id =
      if UserHelpers.is_privileged?(socket.assigns.current_scope),
        do: "create_event_modal",
        else: "book_event_modal"

    {:noreply,
     socket
     |> assign(:selected_event_type, event_type)
     |> push_event("open-modal", %{id: modal_id})}
  end

  defp load_upcoming_events(socket) do
    today = DateTime.to_date(socket.assigns.current_time)

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

    assign(socket, :upcoming, upcoming)
  end

  defp load_event_types(socket) do
    assign(socket, :event_types, Events.list_event_types(:public))
  end
end

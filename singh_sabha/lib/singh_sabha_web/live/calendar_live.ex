defmodule SinghSabhaWeb.CalendarLive do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.CalendarLive.{MonthView, WeekView, DayView}

  def mount(_params, _session, socket) do
    today = Date.utc_today()

    socket =
      socket
      |> assign(:view_mode, :month)
      |> assign(:current_date, today)
      |> assign(:selected_date, today)
      |> load_events()

    {:ok, socket}
  end

  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :view_mode, String.to_atom(view))}
  end

  def handle_event("prev_period", _, socket) do
    new_date = shift_date(socket.assigns.current_date, socket.assigns.view_mode, -1)
    {:noreply, socket |> assign(:current_date, new_date) |> load_events()}
  end

  def handle_event("next_period", _, socket) do
    new_date = shift_date(socket.assigns.current_date, socket.assigns.view_mode, 1)
    {:noreply, socket |> assign(:current_date, new_date) |> load_events()}
  end

  defp load_events(socket) do
    events = [
      %{
        id: 1,
        title: "Team Meeting",
        start: ~U[2026-01-15 10:00:00Z],
        end: ~U[2026-01-15 11:00:00Z]
      },
      %{id: 2, title: "Lunch", start: ~U[2026-01-15 12:00:00Z], end: ~U[2026-01-15 13:00:00Z]},
      %{id: 3, title: "Dinner", start: ~U[2026-01-15 17:00:00Z], end: ~U[2026-01-15 19:00:00Z]},
      %{
        id: 4,
        title: "Project Review",
        start: ~U[2026-01-16 14:00:00Z],
        end: ~U[2026-01-16 16:00:00Z]
      },
      %{
        id: 5,
        title: "Conference",
        start: ~U[2026-01-13 09:00:00Z],
        end: ~U[2026-01-15 17:00:00Z]
      },
      %{id: 6, title: "Vacation", start: ~U[2026-01-20 00:00:00Z], end: ~U[2026-01-25 23:59:59Z]}
    ]

    assign(socket, :events, events)
  end

  defp shift_date(date, :month, offset), do: Date.add(date, offset * 30)
  defp shift_date(date, :week, offset), do: Date.add(date, offset * 7)
  defp shift_date(date, :day, offset), do: Date.add(date, offset)

  defp period_label(date, :month), do: Calendar.strftime(date, "%B %Y")

  defp period_label(date, :week) do
    week_start = Date.beginning_of_week(date, :sunday)
    week_end = Date.add(week_start, 6)
    "#{Calendar.strftime(week_start, "%b %d")} - #{Calendar.strftime(week_end, "%b %d, %Y")}"
  end

  defp period_label(date, :day), do: Calendar.strftime(date, "%A, %B %d, %Y")

  def render(assigns) do
    ~H"""
    <div class="p-2 ">
      <div class="flex justify-between p-4">
        <div class="space-x-4">
          <button phx-click="prev_period" class="btn btn-square">
            <.icon name="hero-chevron-left" />
          </button>

          <span class="text-sm text-base-400">
            {period_label(@current_date, @view_mode)}
          </span>

          <button phx-click="next_period" class="btn btn-square">
            <.icon name="hero-chevron-right" />
          </button>
        </div>
        <div class="join flex justify-end">
          <button class="btn join-item" phx-click="change_view" phx-value-view="month">Month</button>
          <button class="btn join-item" phx-click="change_view" phx-value-view="week">Week</button>
          <button class="btn join-item" phx-click="change_view" phx-value-view="day">Day</button>
        </div>
      </div>

      <%= if @view_mode == :month do %>
        <MonthView.view current_date={@current_date} events={@events} />
      <% end %>

      <%= if @view_mode == :week do %>
        <WeekView.view current_date={@current_date} events={@events} />
      <% end %>

      <%= if @view_mode == :day do %>
        <DayView.view current_date={@current_date} events={@events} />
      <% end %>
    </div>
    """
  end
end

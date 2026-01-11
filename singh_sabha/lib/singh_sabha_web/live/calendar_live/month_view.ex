defmodule SinghSabhaWeb.CalendarLive.MonthView do
  use Phoenix.Component

  import SinghSabhaWeb.Helpers.CalendarHelpers

  def view(assigns) do
    max_visible_events = 3
    {dates, first_display, last_display} = month_dates(assigns.current_date)

    event_positions =
      calculate_event_positions(
        assigns.events,
        first_display,
        last_display,
        max_visible_events
      )

    assigns =
      assigns
      |> assign(:dates, dates)
      |> assign(:event_positions, event_positions)
      |> assign(:max_visible_events, max_visible_events)

    ~H"""
    <div>
      <div class="grid grid-cols-7 divide-x divide-base-300">
        <%= for day <- ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] do %>
          <div class="text-xs text-base-400 font-medium text-center py-2">{day}</div>
        <% end %>
      </div>

      <div class="grid grid-cols-7">
        <%= for date <- @dates do %>
          <.day_cell
            date={date}
            current_date={@current_date}
            events={@events}
            event_positions={@event_positions}
            max_visible_events={@max_visible_events}
          />
        <% end %>
      </div>
    </div>
    """
  end

  defp day_cell(assigns) do
    {segments, overflow} =
      segments_for_date(
        assigns.events,
        assigns.event_positions,
        assigns.date
      )

    assigns =
      assigns
      |> assign(:saturday?, Date.day_of_week(assigns.date) == 6)
      |> assign(:current_month?, assigns.date.month == assigns.current_date.month)
      |> assign(:today?, assigns.date == Date.utc_today())
      |> assign(:segments, segments)
      |> assign(:overflow, overflow)

    ~H"""
    <div class={[
      "flex h-full flex-col gap-1 border-t border-base-300 py-1.5 lg:pb-2 lg:pt-1",
      !@saturday? && "border-r"
    ]}>
      <button
        phx-click="select_date"
        phx-value-date={Date.to_iso8601(@date)}
        class={[
          "flex w-6 h-6 translate-x-1 items-center justify-center rounded-full text-xs font-semibold",
          "hover:bg-gray-100 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-500",
          "lg:px-2",
          !@current_month? && "opacity-20",
          @today? && "bg-blue-500 font-bold text-white hover:bg-blue-500"
        ]}
      >
        {@date.day}
      </button>

      <div class={[
        "flex h-6 gap-1 px-2 lg:h-[94px] lg:flex-col lg:gap-2 lg:px-0",
        !@current_month? && "opacity-50"
      ]}>
        <%= for row <- 0..(@max_visible_events - 1) do %>
          <% segment = Enum.find(@segments, &(&1.row == row)) %>

          <div class={[
            "lg:flex-1",
            segment && segment.starts? && "lg:pl-1",
            segment && segment.ends? && "lg:pr-1"
          ]}>
            <%= if segment do %>
              <div class="w-2 h-2 rounded-full bg-blue-500 lg:hidden"></div>
              <div class={[
                "hidden lg:flex h-6.5 items-center bg-blue-100 text-blue-800 text-xs font-medium -mx-px",
                segment.starts? && "rounded-l-md ml-0",
                segment.ends? && "rounded-r-md mr-0",
                !segment.starts? && "rounded-l-none border-l-0",
                !segment.ends? && "rounded-r-none border-r-0"
              ]}>
                <%= if segment.starts? do %>
                  <div class="flex w-full items-center justify-between px-2 overflow-hidden whitespace-nowrap">
                    <span class="truncate">{segment.event.title}</span>
                    <span>{format_time(segment.event.start)}</span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @overflow > 0 do %>
        <p class={[
          "h-4.5 px-1.5 text-xs font-semibold text-gray-500",
          !@current_month? && "opacity-50"
        ]}>
          <span class="sm:hidden">+{@overflow}</span>
          <span class="hidden sm:inline">+{@overflow} more…</span>
        </p>
      <% end %>
    </div>
    """
  end
end

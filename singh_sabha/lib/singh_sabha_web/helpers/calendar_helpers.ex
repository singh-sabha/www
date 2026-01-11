defmodule SinghSabhaWeb.Helpers.CalendarHelpers do
  def month_dates(date) do
    first_of_month = Date.beginning_of_month(date)
    last_of_month = Date.end_of_month(date)

    days_before_first = rem(Date.day_of_week(first_of_month), 7)
    first_display = Date.add(first_of_month, -days_before_first)

    days_after_last = rem(7 - Date.day_of_week(last_of_month), 7)
    last_display = Date.add(last_of_month, days_after_last)

    total_days = Date.diff(last_display, first_display)

    days =
      Enum.map(0..(total_days - 1), fn i ->
        Date.add(first_display, i)
      end)

    {days, first_display, last_display}
  end

  def format_time(datetime) do
    hour = datetime.hour
    minute = String.pad_leading("#{datetime.minute}", 2, "0")
    period = if hour < 12, do: "AM", else: "PM"
    display_hour = if hour == 0, do: 12, else: if(hour > 12, do: hour - 12, else: hour)
    "#{display_hour}:#{minute} #{period}"
  end

  def segments_for_date(events, event_positions, date) do
    active =
      Enum.filter(events, fn event ->
        start_date = DateTime.to_date(event.start)
        end_date = DateTime.to_date(event.end)

        Date.compare(date, start_date) != :lt and
          Date.compare(date, end_date) != :gt
      end)

    {visible, hidden} =
      Enum.split_with(active, fn event ->
        Map.has_key?(event_positions, event.id)
      end)

    segments =
      Enum.map(visible, fn event ->
        start_date = DateTime.to_date(event.start)
        end_date = DateTime.to_date(event.end)

        %{
          event: event,
          row: event_positions[event.id],
          starts?: date == start_date,
          ends?: date == end_date
        }
      end)

    {segments, length(hidden)}
  end

  def calculate_event_positions(events, first_day, last_day, max_rows) do
    date_range =
      Date.range(first_day, last_day)
      |> Enum.to_list()

    occupied =
      Enum.reduce(date_range, %{}, fn day, acc ->
        Map.put(acc, day, List.duplicate(false, max_rows))
      end)

    sorted_events =
      Enum.sort(events, fn a, b ->
        Date.diff(DateTime.to_date(a.end), DateTime.to_date(a.start)) >=
          Date.diff(DateTime.to_date(b.end), DateTime.to_date(b.start))
      end)

    {positions, _} =
      Enum.reduce(sorted_events, {%{}, occupied}, fn event, {pos_acc, occ} ->
        event_days =
          Enum.filter(date_range, fn day ->
            Date.compare(day, DateTime.to_date(event.start)) != :lt and
              Date.compare(day, DateTime.to_date(event.end)) != :gt
          end)

        row =
          Enum.find(0..(max_rows - 1), fn i ->
            Enum.all?(event_days, fn day -> not Enum.at(occ[day], i) end)
          end)

        if row do
          new_occ =
            Enum.reduce(event_days, occ, fn day, acc ->
              Map.update!(acc, day, &List.replace_at(&1, row, true))
            end)

          {Map.put(pos_acc, event.id, row), new_occ}
        else
          {pos_acc, occ}
        end
      end)

    positions
  end
end

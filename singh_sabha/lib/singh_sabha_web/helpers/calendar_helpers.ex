defmodule SinghSabhaWeb.Helpers.CalendarHelpers do
  def format_time(datetime) do
    hour = datetime.hour
    minute = String.pad_leading("#{datetime.minute}", 2, "0")
    period = if hour < 12, do: "AM", else: "PM"
    display_hour = if hour == 0, do: 12, else: if(hour > 12, do: hour - 12, else: hour)
    "#{display_hour}:#{minute} #{period}"
  end

  def format_hour(hour) do
    period = if hour < 12, do: "AM", else: "PM"
    display_hour = if hour == 0, do: 12, else: if(hour > 12, do: hour - 12, else: hour)
    "#{display_hour} #{period}"
  end

  def format_date(datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y")
  end

  def partition_events(events) do
    Enum.split_with(events, fn event ->
      start_date = DateTime.to_date(event.start)
      end_date = DateTime.to_date(event.end)
      Date.compare(start_date, end_date) == :eq
    end)
  end

  def get_month_label(date, :abbreviation), do: Calendar.strftime(date, "%b")
  def get_month_label(date, :full), do: Calendar.strftime(date, "%B")

  def get_total_events(events, date, :day) do
    Enum.count(events, fn event ->
      event_date = DateTime.to_date(event.start)
      Date.compare(event_date, date) == :eq
    end)
  end

  def get_total_events(events, date, :week) do
    week_start = Date.beginning_of_week(date, :sunday)
    week_end = Date.add(week_start, 6)

    Enum.count(events, fn event ->
      event_date = DateTime.to_date(event.start)

      Date.compare(event_date, week_start) in [:eq, :gt] and
        Date.compare(event_date, week_end) in [:eq, :lt]
    end)
  end

  def get_total_events(events, date, :month) do
    Enum.count(events, fn event ->
      event_date = DateTime.to_date(event.start)
      event_date.year == date.year and event_date.month == date.month
    end)
  end

  def get_visible_hours(:working_hours, working_hours),
    do: Enum.to_list(working_hours.start..working_hours.end)

  def get_visible_hours(:all_hours, _working_hours), do: Enum.to_list(0..23)

  def group_overlapping_events(events) do
    sorted = Enum.sort_by(events, & &1.start, DateTime)

    Enum.reduce(sorted, [], fn event, groups ->
      event_start = event.start

      group_index =
        Enum.find_index(groups, fn group ->
          last_event = List.last(group)
          last_event_end = last_event.end
          DateTime.compare(event_start, last_event_end) != :lt
        end)

      case group_index do
        nil ->
          groups ++ [[event]]

        index ->
          List.update_at(groups, index, fn group -> group ++ [event] end)
      end
    end)
  end

  def events_overlap?(event1, event2) do
    DateTime.compare(event1.start, event2.end) == :lt and
      DateTime.compare(event1.end, event2.start) == :gt
  end

  def working_hour?(day, hour, working_hours) do
    day_of_week = Date.day_of_week(day)

    weekday? = day_of_week >= 1 and day_of_week <= 5

    weekday? and hour >= working_hours.start and hour < working_hours.end
  end

  def get_event_style(event, relative_position, total_overlapping, hours) do
    first_hour = List.first(hours)
    last_hour = List.last(hours)

    start_minutes = event.start.hour * 60 + event.start.minute
    end_minutes = event.end.hour * 60 + event.end.minute

    visible_start_minutes = first_hour * 60
    visible_end_minutes = (last_hour + 1) * 60
    visible_range = visible_end_minutes - visible_start_minutes

    top = (start_minutes - visible_start_minutes) / visible_range * 100
    height = (end_minutes - start_minutes) / visible_range * 100

    width = 100 / total_overlapping
    left = relative_position * width

    "top: #{top}%; height: #{height}%; width: #{width}%; left: #{left}%;"
  end
end

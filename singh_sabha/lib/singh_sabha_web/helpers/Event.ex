defmodule SinghSabhaWeb.Helpers.Event do
  def find_event(event_id, events) when is_binary(event_id) do
    Enum.find(events, fn event ->
      event.id == String.to_integer(event_id)
    end)
  end

  def find_event(event_id, events) when is_integer(event_id) do
    Enum.find(events, fn event ->
      event.id == event_id
    end)
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

  def get_total_events(events, date, :agenda) do
    Enum.count(events, fn event ->
      event_start = DateTime.to_date(event.start)
      event_start.year == date.year && event_start.month == date.month
    end)
  end

  def get_total_events(events, date, :day) do
    Enum.count(events, fn event ->
      start_date = DateTime.to_date(event.start)
      end_date = DateTime.to_date(event.end)

      Date.compare(date, start_date) != :lt and
        Date.compare(date, end_date) != :gt
    end)
  end

  def get_total_events(events, date, :week) do
    week_start = Date.beginning_of_week(date, :sunday)
    week_end = Date.end_of_week(date, :sunday)

    Enum.count(events, fn event ->
      start_date = DateTime.to_date(event.start)
      end_date = DateTime.to_date(event.end)

      Date.compare(start_date, week_end) != :gt and
        Date.compare(end_date, week_start) != :lt
    end)
  end

  def get_total_events(events, date, :month) do
    month_start = Date.beginning_of_month(date)
    month_end = Date.end_of_month(date)

    Enum.count(events, fn event ->
      start_date = DateTime.to_date(event.start)
      end_date = DateTime.to_date(event.end)

      Date.compare(start_date, month_end) != :gt and
        Date.compare(end_date, month_start) != :lt
    end)
  end

  def get_visible_hours(:working_hours, working_hours),
    do: Enum.to_list(working_hours.start..working_hours.end)

  def get_visible_hours(:all_hours, _working_hours), do: Enum.to_list(0..23)

  def get_overlap_info(grouped_events) do
    for {group, group_index} <- Enum.with_index(grouped_events),
        event <- group do
      overlapping_group_indices =
        grouped_events
        |> Enum.with_index()
        |> Enum.filter(fn {other_group, other_index} ->
          other_index == group_index or
            Enum.any?(other_group, fn other_event ->
              events_overlap?(event, other_event)
            end)
        end)
        |> Enum.map(fn {_group, index} -> index end)

      {event, group_index, overlapping_group_indices}
    end
  end

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

defmodule SinghSabhaWeb.Helpers.Timezone do
  def local do
    Application.get_env(:singh_sabha, :timezone, "America/Vancouver")
  end

  def to_local(utc_datetime) do
    DateTime.shift_zone!(utc_datetime, local())
  end

  def format(utc_datetime, format_string \\ "%B %d, %Y at %I:%M %p") do
    utc_datetime
    |> to_local()
    |> Calendar.strftime(format_string)
  end

  def local_to_utc(datetime_string) when is_binary(datetime_string) do
    with {:ok, naive} <- NaiveDateTime.from_iso8601(datetime_string <> ":00"),
         {:ok, local_dt} <- DateTime.from_naive(naive, local()) do
      {:ok, DateTime.shift_zone!(local_dt, "Etc/UTC")}
    end
  end

  def local_to_utc_full(datetime_string) when is_binary(datetime_string) do
    normalized = String.replace(datetime_string, " ", "T")

    with {:ok, naive} <- NaiveDateTime.from_iso8601(normalized),
         {:ok, local_dt} <- DateTime.from_naive(naive, local()) do
      {:ok, DateTime.shift_zone!(local_dt, "Etc/UTC")}
    end
  end

  def utc_to_local(%DateTime{} = utc_datetime) do
    DateTime.shift_zone!(utc_datetime, local())
  end

  def utc_to_local(datetime_string) when is_binary(datetime_string) do
    with {:ok, datetime, _offset} <- DateTime.from_iso8601(datetime_string) do
      {:ok, DateTime.shift_zone!(datetime, local())}
    end
  end

  def convert_datetime_params(params) do
    Enum.reduce(["start", "end"], params, fn field, acc ->
      Map.update(acc, field, nil, fn value ->
        case local_to_utc(value) do
          {:ok, utc_datetime} -> utc_datetime
          {:error, _} -> value
        end
      end)
    end)
  end

  def convert_event_to_local(%{start: start, end: end_time} = event) do
    %{event | start: utc_to_local(start), end: utc_to_local(end_time)}
  end

  def format_time(%DateTime{} = utc_datetime) do
    datetime = to_local(utc_datetime)
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

  def format_date(%DateTime{} = utc_datetime) do
    utc_datetime
    |> to_local()
    |> Calendar.strftime("%b %-d, %Y")
  end

  def format_datetime(%DateTime{} = utc_datetime) do
    utc_datetime
    |> to_local()
    |> Calendar.strftime("%b %-d, %Y %-I:%M %p")
  end
end

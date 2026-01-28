defmodule SinghSabhaWeb.Helpers.TimezoneHelpers do
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

  def naive_to_utc(naive_datetime_string) when is_binary(naive_datetime_string) do
    with {:ok, naive} <- NaiveDateTime.from_iso8601(naive_datetime_string),
         {:ok, local_dt} <- DateTime.from_naive(naive, local()) do
      {:ok, DateTime.shift_zone!(local_dt, "UTC")}
    end
  end
end

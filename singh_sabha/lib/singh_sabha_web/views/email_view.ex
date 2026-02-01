defmodule SinghSabhaWeb.EmailView do
  use Phoenix.View,
    root: "lib/singh_sabha_web/templates",
    namespace: SinghSabhaWeb

  def format_date(date) do
    Calendar.strftime(date, "%B %-d, %Y")
  end

  def format_date_range(start_date, end_date) do
    start_str = format_date(start_date)
    end_str = format_date(end_date)

    if start_str == end_str do
      start_str
    else
      "#{start_str} - #{end_str}"
    end
  end
end

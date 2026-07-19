defmodule SinghSabhaWeb.Helpers.EventType do
  def event_type_to_colour("Other"), do: :gray
  def event_type_to_colour("Funeral"), do: :green
  def event_type_to_colour("Sukhmani Sahib Path"), do: :blue
  def event_type_to_colour("Sehaj Path"), do: :red
  def event_type_to_colour("Akhand Path"), do: :orange
  def event_type_to_colour("Langar"), do: :purple
  def event_type_to_colour("Anand Karaj"), do: :yellow

  def event_status_colour(is_verified, is_deposit_paid) do
    cond do
      !is_verified -> "border-l-4 border-l-red-500"
      is_verified && !is_deposit_paid -> "border-l-4 border-l-yellow-500"
      true -> "border-l-4 border-l-green-500"
    end
  end
end

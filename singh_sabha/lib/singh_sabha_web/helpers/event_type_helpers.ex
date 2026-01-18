defmodule SinghSabhaWeb.Helpers.EventTypeHelpers do
  def event_type_to_colour("Akhand Path"), do: :green
  def event_type_to_colour(_), do: :gray

  def badge_colour(colour) do
    c = colour_name(colour)

    "border-#{c}-200 bg-#{c}-50 text-#{c}-700 " <>
      "dark:border-#{c}-800 dark:bg-#{c}-950 dark:text-#{c}-300"
  end

  def dot_colour(colour) do
    "bg-#{colour_name(colour)}-600"
  end

  defp colour_name(:blue), do: "blue"
  defp colour_name(:green), do: "green"
  defp colour_name(:red), do: "red"
  defp colour_name(:orange), do: "orange"
  defp colour_name(:purple), do: "purple"
  defp colour_name(:yellow), do: "yellow"
  defp colour_name(:gray), do: "neutral"
end

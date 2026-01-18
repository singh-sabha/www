defmodule SinghSabhaWeb.Helpers.EventTypeHelpers do
  def event_type_to_colour("Akhand Path"), do: :green
  def event_type_to_colour(_), do: :gray

  def badge_colour(:green) do
    "border-green-200 bg-green-50 text-green-700 " <>
      "dark:border-green-800 dark:bg-green-950 dark:text-green-300"
  end

  def badge_colour(:gray) do
    "border-neutral-200 bg-neutral-50 text-neutral-700 " <>
      "dark:border-neutral-800 dark:bg-neutral-950 dark:text-neutral-300"
  end

  def badge_colour(:blue) do
    "border-blue-200 bg-blue-50 text-blue-700 " <>
      "dark:border-blue-800 dark:bg-blue-950 dark:text-blue-300"
  end

  def badge_colour(:red) do
    "border-red-200 bg-red-50 text-red-700 " <>
      "dark:border-red-800 dark:bg-red-950 dark:text-red-300"
  end

  def badge_colour(:orange) do
    "border-orange-200 bg-orange-50 text-orange-700 " <>
      "dark:border-orange-800 dark:bg-orange-950 dark:text-orange-300"
  end

  def badge_colour(:purple) do
    "border-purple-200 bg-purple-50 text-purple-700 " <>
      "dark:border-purple-800 dark:bg-purple-950 dark:text-purple-300"
  end

  def badge_colour(:yellow) do
    "border-yellow-200 bg-yellow-50 text-yellow-700 " <>
      "dark:border-yellow-800 dark:bg-yellow-950 dark:text-yellow-300"
  end

  def dot_colour(:green), do: "bg-green-600"
  def dot_colour(:gray), do: "bg-neutral-600"
  def dot_colour(:blue), do: "bg-blue-600"
  def dot_colour(:red), do: "bg-red-600"
  def dot_colour(:orange), do: "bg-orange-600"
  def dot_colour(:purple), do: "bg-purple-600"
  def dot_colour(:yellow), do: "bg-yellow-600"
end

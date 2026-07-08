defmodule SinghSabhaWeb.Helpers.User do
  def generate_gradient_colours(seed) do
    hash = :erlang.phash2(seed)

    colours = [
      {"#667eea", "#764ba2"},
      {"#f093fb", "#f5576c"},
      {"#4facfe", "#00f2fe"},
      {"#43e97b", "#38f9d7"},
      {"#fa709a", "#fee140"},
      {"#30cfd0", "#330867"},
      {"#a8edea", "#fed6e3"},
      {"#ff9a56", "#ff6a88"},
      {"#f7971e", "#ffd200"},
      {"#21d4fd", "#b721ff"},
      {"#08aeea", "#2af598"},
      {"#8ec5fc", "#e0c3fc"},
      {"#d4fc79", "#96e6a1"},
      {"#f77062", "#fe5196"},
      {"#c471ed", "#12c2e9"},
      {"#f64f59", "#c0392b"},
      {"#56ab2f", "#a8e063"},
      {"#eecda3", "#ef629f"},
      {"#2193b0", "#6dd5ed"},
      {"#cc2b5e", "#753a88"},
      {"#42275a", "#734b6d"},
      {"#bdc3c7", "#2c3e50"},
      {"#de6161", "#2657eb"},
      {"#1a1a2e", "#16213e"},
      {"#f3904f", "#3b4371"},
      {"#0f0c29", "#302b63"},
      {"#e96443", "#904e95"},
      {"#00b09b", "#96c93d"},
      {"#fd746c", "#ff9068"},
      {"#3f2b96", "#a8c0ff"}
    ]

    {colour1, colour2} = Enum.at(colours, rem(hash, length(colours)))
    "#{colour1}, #{colour2}"
  end

  def generate_guest_name(seed) do
    nouns = ~w(
      Fox Owl Bear Wolf Hawk Deer Lynx Crow Swan Eagle
      Tiger Lion Crane Bison Raven Moose Heron Otter Finch Stag
    )

    hash = :erlang.phash2(seed)

    "Anonymous #{Enum.at(nouns, rem(hash, length(nouns)))}"
  end

  def privileged?(%SinghSabha.Accounts.Scope{user: user}), do: user.role in ~w(mod admin)
  def privileged?(%{current_scope: scope}), do: privileged?(scope)
  def privileged?(_), do: false
end

defmodule SinghSabhaWeb.Helpers.UserHelpers do
  def generate_gradient_colours(email) do
    hash = :erlang.phash2(email)

    colors = [
      {"#667eea", "#764ba2"},
      {"#f093fb", "#f5576c"},
      {"#4facfe", "#00f2fe"},
      {"#43e97b", "#38f9d7"},
      {"#fa709a", "#fee140"},
      {"#30cfd0", "#330867"},
      {"#a8edea", "#fed6e3"},
      {"#ff9a56", "#ff6a88"}
    ]

    {color1, color2} = Enum.at(colors, rem(hash, length(colors)))
    "#{color1}, #{color2}"
  end
end

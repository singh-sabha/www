defmodule SinghSabha.Repo do
  use Ecto.Repo,
    otp_app: :singh_sabha,
    adapter: Ecto.Adapters.Postgres
end

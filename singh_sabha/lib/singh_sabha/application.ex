defmodule SinghSabha.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    SinghSabha.Release.migrate()

    children = [
      SinghSabha.PromEx,
      SinghSabhaWeb.Telemetry,
      SinghSabha.Repo,
      {DNSCluster, query: Application.get_env(:singh_sabha, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SinghSabha.PubSub},
      SinghSabhaWeb.Presence,
      # Start a worker by calling: SinghSabha.Worker.start_link(arg)
      # {SinghSabha.Worker, arg},
      # Start to serve requests, typically the last entry
      SinghSabhaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SinghSabha.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SinghSabhaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

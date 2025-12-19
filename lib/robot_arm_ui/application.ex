defmodule RobotArmUi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RobotArmUiWeb.Telemetry,
      RobotArmUi.Repo,
      {DNSCluster, query: Application.get_env(:robot_arm_ui, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RobotArmUi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RobotArmUi.Finch},
      # Start a worker by calling: RobotArmUi.Worker.start_link(arg)
      # {RobotArmUi.Worker, arg},
      # Start to serve requests, typically the last entry
      RobotArmUiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RobotArmUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RobotArmUiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

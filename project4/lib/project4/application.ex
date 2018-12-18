defmodule Project4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Project4.Super
  alias Project4.Network
  alias Project4.Exchange

  def start(_type, _args) do
    run_spec = {Registry,
    keys: :unique,
    name: Project4.Registry,
    partitions: 2*System.schedulers_online()}
    svr_spec = {DynamicSupervisor,
    strategy: :one_for_one,
    name: Project4.DynamicSupervisor}

    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Project4.Repo,
      # Start the endpoint when the application starts
      Project4Web.Endpoint,
      run_spec,
      svr_spec,
      Supervisor.child_spec({Project4.Network, []}, restart: :transient),
      Supervisor.child_spec({Project4.Exchange, []}, restart: :transient),
      #Supervisor.child_spec({Project4.Super, []}, restart: :transient)
      # Starts a worker by calling: Project4.Worker.start_link(arg)
      # {Project4.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Project4.Supervisor]
    {:ok,id} = Supervisor.start_link(children, opts)
    {:ok, sup} = DynamicSupervisor.start_child(Project4.DynamicSupervisor,
    Supervisor.child_spec({Super, 0}, id: {Super, 0}, restart: :transient))

    GenServer.cast(sup, {:initialize})

    {:ok, id}
  end
  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Project4Web.Endpoint.config_change(changed, removed)
    :ok
  end
end

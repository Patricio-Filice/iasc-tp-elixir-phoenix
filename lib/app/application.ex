defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @to_do_list_registry App.ToDoList.Registry
  @to_do_list_agent_registry App.ToDoList.Agent.Registry

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: @to_do_list_registry,
        start: { Registry, :start_link, [:duplicate, @to_do_list_registry] }
      },
      %{
        id: @to_do_list_agent_registry,
        start: { Registry, :start_link, [:duplicate, @to_do_list_agent_registry] }
      },
      {App.ToDoList.Node.Agent, :tasks_states},
      App.ToDoList.Task.State.Tracer,
      # Start the Telemetry supervisor
      App.ToDoList.NodeObserver.Supervisor,
      AppWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Start the Endpoint (http/https)
      AppWeb.Endpoint,
      App.ToDoList.Task.Supervisor,
      App.ToDoList.Agent.Supervisor,
      App.ToDoList.Worker,
      # Cluster supervisor
      {Cluster.Supervisor, [topologies(), [name: App.ToDoList.Cluster.Supervisor]]}
      ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp topologies do
    [
      app: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
  end
end

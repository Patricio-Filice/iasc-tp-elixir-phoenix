defmodule App.ToDoList.NodeObserver do
  use GenServer
  require Logger

  #alias App.ToDoList.{HordeRegistry, HordeSupervisor}

  def start_link(_)do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl GenServer
  def init(state) do
    # https://erlang.org/doc/man/net_kernel.html#monitor_nodes-1
    :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:nodedown, node, _node_type}, state) do
    :telemetry.execute(
      [:node, :event, :down],
      %{node_affected: node},
      %{}
    )
    IO.puts("node down")
    IO.puts(node)
    App.ToDoList.Task.State.Tracer.dismiss(node)
    #set_members(HordeRegistry)
    set_members(App.ToDoList.Task.Supervisor)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:nodeup, node, _node_type}, state) do
    :telemetry.execute(
      [:node, :event, :up],
      %{node_affected: node},
      %{}
    )
    IO.puts("node up")
    IO.puts(node)
    App.ToDoList.Task.State.Tracer.handshake(node)
    #set_members(HordeRegistry)
    set_members(App.ToDoList.Task.Supervisor)

    {:noreply, state}
  end

  defp set_members(name) do
    members = Enum.map([Node.self() | Node.list()], &{name, &1})

    :ok = Horde.Cluster.set_members(name, members)
  end
end

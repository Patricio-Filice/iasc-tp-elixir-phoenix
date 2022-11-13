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
    IO.puts(node)
    #set_members(HordeRegistry)
    #set_members(HordeSupervisor)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:nodeup, node, _node_type}, state) do
    :telemetry.execute(
      [:node, :event, :up],
      %{node_affected: node},
      %{}
    )
    IO.puts(node)
    #set_members(HordeRegistry)
    #set_members(HordeSupervisor)

    {:noreply, state}
  end
end

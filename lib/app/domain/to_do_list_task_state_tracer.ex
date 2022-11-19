defmodule App.ToDoList.Task.State.Tracer do
  use GenServer

  @to_do_list_agent_registry App.ToDoList.Agent.Registry
  @agent :tasks_states

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    App.ToDoList.Node.Agent.update(@agent, node(), Process.whereis(__MODULE__))
    { :ok, nil }
  end

  def get_any_local_agent_pid() do
    Enum.random(get_local_agents_pids())
  end

  defp get_local_agents_pids() do
    Registry.lookup(@to_do_list_agent_registry, App.ToDoList.Agent)
  end

  def get_agents_pids() do
    task_state_tracers_pids = App.ToDoList.Node.Agent.get_values(@agent)
    map = fn pid ->
      GenServer.call(pid, :get_agents_pids)
    end
    Enum.flat_map(task_state_tracers_pids, map)
  end

  @impl true
  def handle_call({ :accept_handshake, node, pid }, _from, state) do
    App.ToDoList.Node.Agent.update(@agent, node, pid)
    { :reply, self(), state }
  end

  @impl true
  def handle_call(:get_agents_pids, _from, state) do
    { :reply, get_local_agents_pids(), state }
  end

  def get_local_agent_registry_pid() do
    Process.whereis(@to_do_list_agent_registry)
  end

  def handshake(node) do
    App.ToDoList.Node.Agent.update(@agent, node, GenServer.call({__MODULE__, :"#{node}"}, { :accept_handshake, node(), Process.whereis(__MODULE__) }))
  end

  def dismiss(node) do
    App.ToDoList.Node.Agent.delete(@agent, node)
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [:ok] }
    }
  end
end

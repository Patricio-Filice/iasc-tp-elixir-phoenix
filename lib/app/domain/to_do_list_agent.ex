defmodule App.ToDoList.Agent do
  use Agent

  @to_do_list_agent_registry App.ToDoList.Agent.Registry

  def start_link(init_arg) do
    Agent.start_link(fn ->
      Registry.register(@to_do_list_agent_registry, App.ToDoList.Agent, init_arg)
      %{}
    end)
  end

  def child_spec(init_arg) do
    %{
      id: init_arg,
      start: { __MODULE__, :start_link, [init_arg] }
    }
  end

  def get(agent_pid, key) do
    Agent.get(agent_pid, &Map.get(&1, key, %{}))
  end

  def update(agent_pid, key, value) do
    Agent.update(agent_pid, &Map.put(&1, key, value))
  end
end

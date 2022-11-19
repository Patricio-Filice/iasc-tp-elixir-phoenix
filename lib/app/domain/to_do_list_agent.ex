defmodule App.ToDoList.Agent do
  use Agent

  @to_do_list_agent_registry App.ToDoList.Agent.Registry

  def start_link(init_arg) do
    Agent.start_link(fn ->
      reducer = fn { agent_pid, _ }, map ->
        if (map == %{}) do
          App.ToDoList.Agent.get(agent_pid)
        else
          map
        end
      end
      map = Enum.reduce(App.ToDoList.Task.State.Tracer.get_agents_pids(), %{}, reducer)
      Registry.register(@to_do_list_agent_registry, App.ToDoList.Agent, init_arg)
      map
    end)
  end

  def child_spec(init_arg) do
    %{
      id: init_arg,
      start: { __MODULE__, :start_link, [init_arg] }
    }
  end

  def get(agent_pid) do
    Agent.get(agent_pid, & &1)
  end

  def get(agent_pid, key) do
    Agent.get(agent_pid, &Map.get(&1, key, %{}))
  end

  def get(agent_pid, list_name, task_id) do
    get_task = fn am ->
      Map.get(Map.get(am, list_name, %{}), task_id)
    end
    Agent.get(agent_pid, get_task)
  end

  def update(agent_pid, key, value) do
    Agent.update(agent_pid, &Map.put(&1, key, value))
  end

  def update(agent_pid, list_name, task_id, task) do
    put_task = fn am ->
      list_map = Map.get(am, list_name, %{})
      Map.put(am, list_name, Map.put(list_map, task_id, task))
    end
    Agent.update(agent_pid, put_task)
  end

  def delete(agent_pid, list_name, task_id) do
    put_task = fn am ->
      list_map = Map.get(am, list_name, %{})
      Map.put(am, list_name, Map.delete(list_map, task_id))
    end
    Agent.update(agent_pid, put_task)
  end
end

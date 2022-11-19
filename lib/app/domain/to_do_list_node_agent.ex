defmodule App.ToDoList.Node.Agent do
  use Agent

  def start_link(init_arg) do
    Agent.start_link(fn -> %{} end, name: init_arg)
  end

  def child_spec(init_arg) do
    %{
      id: init_arg,
      start: { __MODULE__, :start_link, [init_arg] }
    }
  end

  def get_values(name) do
    Agent.get(name, & Map.values(&1))
  end

  def get(name, node) do
    Agent.get(name, &Map.get(&1, node, %{}))
  end

  def update(name, node, pid) do
    Agent.update(name, &Map.put(&1, node, pid))
  end

  def delete(name, node) do
    Agent.update(name, &Map.delete(&1, node))
  end
end

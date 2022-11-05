defmodule App.ToDoList.Agent.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {App.ToDoList.Agent, [:zero]},
      {App.ToDoList.Agent, [:one]},
      {App.ToDoList.Agent, [:two]}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def child_spec do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link }
    }
  end
end

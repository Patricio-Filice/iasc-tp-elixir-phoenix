defmodule App.ToDoList.Task.Supervisor do
  use Horde.DynamicSupervisor

  def start_link(_init_arg) do
    opts = [
      strategy: :one_for_one,
      distribution_strategy: Horde.UniformDistribution
    ]
    Horde.DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end


  def child_spec do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link }
    }
  end

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  def start_child(name) do
    toDoListWorkerSpec = { App.ToDoList.Task.Worker, [name] }
    Horde.DynamicSupervisor.start_child(__MODULE__, toDoListWorkerSpec)
  end

  defp members() do
    Enum.map([Node.self() | Node.list()], &{__MODULE__, &1})
  end
end

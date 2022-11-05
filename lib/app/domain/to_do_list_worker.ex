
defmodule App.ToDoList.Worker do
  use GenServer

  @to_do_list_registry App.ToDoList.Registry

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    { :ok, nil }
  end

  def where_is(list_name) do
    case Registry.lookup(@to_do_list_registry, list_name) do
      [] -> nil
      todo_lists -> Enum.random(todo_lists)
    end
  end

  def all() do
    Registry.select(@to_do_list_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end

  def create(name) do
    App.ToDoList.Task.Supervisor.start_child(name)
  end

  def call(name, message) do
    try_reach(name, fn pid -> GenServer.call(pid, message) end)
  end

  def cast(name, message) do
    try_reach(name, fn pid -> GenServer.cast(pid, message) end)
  end

  defp try_reach(name, action) do
    case where_is(name) do
      { pid, _ } -> action.(pid)
      _ -> { :to_do_list_not_found, %{ code: "LIST_NOT_FOUND", message: "La lista solicitada no pudo ser encontrada" } }
    end
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [:ok] }
    }
  end
end

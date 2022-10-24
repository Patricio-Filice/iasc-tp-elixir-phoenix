
defmodule App.ToDoList.Worker do
  use GenServer

  @to_do_list_registry :to_do_list_registry

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    { :ok, nil }
  end

  def where_is(list_name) do
    case Registry.lookup(@to_do_list_registry, list_name) do
      [{ pid, _ }] -> pid
      [] -> { :to_do_list_not_found, "The requested list couldn't be found" }
    end
  end

  def all() do
    Registry.select(@to_do_list_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end

  def create(name) do
    App.ToDoList.Task.Supervisor.start_child(name)
  end

  def call(name, message) do
    GenServer.call(where_is(name), message)
  end

  def cast(name, message) do
    GenServer.cast(where_is(name), message)
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [:ok] }
    }
  end
end

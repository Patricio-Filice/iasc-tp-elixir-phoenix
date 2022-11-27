
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
    worker = case Registry.lookup(@to_do_list_registry, list_name) do
      [] -> nil
      todo_lists -> Enum.random(todo_lists)
    end

    if (worker == nil) do
      nodes = Node.list()
      reducer = fn node, w ->
        if (w == nil) do
          GenServer.call({__MODULE__, :"#{node}"}, { :where_is, list_name })
        else
          w
        end
      end
      Enum.reduce(nodes, worker, reducer)
    else
      worker
    end
  end

  def all() do
    nodes = [ node() | Node.list() ]
    map = fn node ->
      GenServer.call({__MODULE__, :"#{node}"}, :all)
    end
    Enum.flat_map(nodes, map)
  end

  def create(name) do
    App.ToDoList.Task.Supervisor.start_child(name)
  end

  def call(name, message) do
    try_reach(name, fn pid -> GenServer.call(pid, message) end)
  end

  def cast(name, message) do
    on_found = fn pid ->
      case message do
        { :swap_task, end_list, task_id } -> try_reach(end_list, fn _ -> GenServer.cast(pid, { :swap_task, end_list, task_id }) end)
        m -> GenServer.cast(pid, m)
      end
    end
    try_reach(name, on_found)
  end

  defp try_reach(name, action) do
    case where_is(name) do
      { pid, _ } -> action.(pid)
      _ -> { :to_do_list_not_found, %{ code: "LIST_NOT_FOUND", message: "La lista solicitada no pudo ser encontrada" } }
    end
  end

  @impl true
  def handle_call({ :where_is, list_name }, _from, state) do
    case Registry.lookup(@to_do_list_registry, list_name) do
      [] -> { :reply, nil, state }
      todo_lists -> { :reply, Enum.random(todo_lists), state }
    end
  end

  @impl true
  def handle_call(:all , _from, state) do
    { :reply, Registry.select(@to_do_list_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}]), state }
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [:ok] }
    }
  end
end

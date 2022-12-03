
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
      todo_lists -> try_sync_and_get(list_name, todo_lists)
    end

    if (worker == nil) do
      nodes = Node.list()
      reducer = fn n, w ->
        if (w == nil) do
          GenServer.call({__MODULE__, :"#{n}"}, { :get_list, list_name })
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
    nodes = Node.list()
    map = fn node ->
      GenServer.call({__MODULE__, :"#{node}"}, :list_all)
    end
    list_local_workers() ++ Enum.flat_map(nodes, map)
  end

  def create(name) do
    case where_is(name) do
      nil -> App.ToDoList.Task.Supervisor.start_child(name)
      _ -> { :duplicated_to_do_list, %{ code: "DUPLICATED_LIST", message: "La lista no pudo ser creada debido a que ya existe en el sistema" } }
    end
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
  def handle_call({ :get_list, list_name }, _from, state) do
    case Registry.lookup(@to_do_list_registry, list_name) do
      [] -> { :reply, nil, state }
      todo_lists -> { :reply, try_sync_and_get(list_name, todo_lists), state }
    end
  end

  @impl true
  def handle_call(:list_all , _from, state) do
    { :reply, list_local_workers(), state }
  end

  def sync() do
    workers = all()
    IO.inspect(workers)
    grouped_workers = Enum.group_by(workers, fn { name, _, _ } -> name end, fn { _, pid, date } -> { pid, date } end)
    Enum.each(grouped_workers, fn { _, list_workers } ->
      list_workers_count =  Enum.count(list_workers)
      if (list_workers_count > 1) do
        sorted_workers = Enum.sort_by(list_workers, fn { _ , date } -> date end, :desc)
        redundant_workers = Enum.take(sorted_workers, list_workers_count - 1)
        Enum.each(redundant_workers, fn { redundant_worker_pid, _ } -> App.ToDoList.Task.Supervisor.terminate_child(redundant_worker_pid) end)
      end
    end)
  end

  def try_sync_and_get(list_name, todo_lists) do
    if (Enum.count(todo_lists) > 1) do
      sync()
    end
    case Registry.lookup(@to_do_list_registry, list_name) do
      [] ->  nil
      tl -> Enum.random(tl)
    end
  end

  defp list_local_workers() do
    Registry.select(@to_do_list_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [:ok] }
    }
  end
end

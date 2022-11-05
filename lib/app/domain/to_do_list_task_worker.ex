defmodule App.ToDoList.Task.Worker do
  use GenServer

  @unmarked_task :unchecked
  @marked_task :checked
  @to_do_list_registry App.ToDoList.Registry

  def start_link(name) do
    GenServer.start_link(__MODULE__, { name })
  end

  @impl true
  def init({ name }) do
    Registry.register(@to_do_list_registry, name, App.ToDoList.Task.Worker)
    { :ok, { name } }
  end

  @impl true
  def handle_cast({ :mark_task, task_id }, { name }) do
    change_task_mark(task_id, @marked_task, { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :unmark_task, task_id }, { name }) do
    change_task_mark(task_id, @unmarked_task, { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :edit_task, task_id, text }, { name }) do
    on_found = fn task ->
      put_task({ task_id, task.mark, text }, { name })
      { :noreply, { name } }
    end
    do_action_on_task(name, task_id, on_found)
  end

  @impl true
  def handle_cast({ :remove_task, task_id }, { name }) do
    new_tasks = Map.delete(get_tasks(name), task_id)
    update_tasks(name, new_tasks)
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :swap_task, to_list, task_id }, { name }) do
    on_found = fn (task) ->
      App.ToDoList.Worker.call(to_list, { :add_task, task.mark, task.text })
      handle_cast({ :remove_task, task_id }, { name })
    end
    do_action_on_task(name, task_id, on_found)
  end

  @impl true
  def handle_call({ :add_task, mark, text }, _from, { name }) do
    id = UUID.uuid4()
    put_task({ id, mark, text }, { name })
    { :reply, id, { name } }
  end

  @impl true
  def handle_call(:list_tasks, _from, { name }) do
    { :reply, get_tasks(name), { name } }
  end

  def change_task_mark(task_id, mark, { name }) do
    on_found = fn task ->
      put_task({ task_id, mark, task.text }, { name })
    end
    do_action_on_task(name, task_id, on_found)
  end

  def put_task({ id, mark, text }, { name }) do
    tasks_map = get_tasks(name)
    new_tasks = Map.put(tasks_map, id, %{ mark: mark, text: text })
    update_tasks(name, new_tasks)
  end

  def do_action_on_task(name, id, on_found) do
    tasks_map = get_tasks(name)
    task = Map.get(tasks_map, id)
    case task do
      nil -> { :task_not_found, %{ code: "TASK_NOT_FOUND", message: "The requested task couldn't be found" } }
      _ ->  on_found.(task)
    end
  end

  def child_spec(name) do
    %{
      id: name,
      start: { __MODULE__, :start_link, name }
    }
  end

  defp get_tasks(name) do
    { agent_pid, _ } = Enum.random(Registry.lookup(App.ToDoList.Agent.Registry, App.ToDoList.Agent))
    App.ToDoList.Agent.get(agent_pid, name)
  end

  defp update_tasks(name, tasks) do
    agent_pids = Registry.lookup(App.ToDoList.Agent.Registry, App.ToDoList.Agent)
    Enum.each(agent_pids, fn { agent_pid, _ } -> App.ToDoList.Agent.update(agent_pid, name, tasks) end)
    :ok
  end
end

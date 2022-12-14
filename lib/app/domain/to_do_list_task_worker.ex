defmodule App.ToDoList.Task.Worker do
  use GenServer

  @unmarked_task :unchecked
  @marked_task :checked
  @to_do_list_registry App.ToDoList.Registry
  @deleted_tasks_cache :deleted_tasks
  @deleted_tasks_cache_ttl 86400000 # A full day

  def start_link(name) do
    GenServer.start_link(__MODULE__, { name })
  end

  @impl true
  def init({ name }) do
    Registry.register(@to_do_list_registry, name, DateTime.utc_now())
    { :ok, { name } }
  end

  @impl true
  def handle_cast({ :mark_task, task_id }, { name }) do
    change_task_mark(task_id, @marked_task, DateTime.utc_now(), { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :mark_task, task_id, modificationDate }, { name }) do
    change_task_mark(task_id, @marked_task, modificationDate, { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :unmark_task, task_id }, { name }) do
    change_task_mark(task_id, @unmarked_task, DateTime.utc_now(), { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :unmark_task, task_id, modificationDate }, { name }) do
    change_task_mark(task_id, @marked_task, modificationDate, { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :edit_task, task_id, text }, { name }) do
    on_found = fn task ->
      put_task({ task_id, task.mark, text, Map.put(task.modificationDates, :text, DateTime.utc_now()) }, { name })
      { :noreply, { name } }
    end
    do_action_on_task(name, task_id, on_found)
  end

  @impl true
  def handle_cast({ :edit_task, task_id, text, modificationDate }, { name }) do
    on_found = fn task ->
      put_task({ task_id, task.mark, text, Map.put(task.modificationDates, :text, modificationDate) }, { name })
      { :noreply, { name } }
    end
    do_action_on_task(name, task_id, on_found)
  end

  @impl true
  def handle_cast({ :remove_task, task_id }, { name }) do
    agent_pids = App.ToDoList.Task.State.Manager.get_agents_pids()
    Enum.each(agent_pids, fn agent_pid -> App.ToDoList.Agent.delete(agent_pid, name, task_id) end)
    Cachex.put(@deleted_tasks_cache, task_id, DateTime.utc_now(), ttl: @deleted_tasks_cache_ttl)
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
  def handle_cast({ :recover_task, id, mark, text, modificationDates }, { name }) do
    put_task({ id, mark, text, modificationDates }, { name })
    { :noreply, id, { name } }
  end

  @impl true
  def handle_call({ :add_task, mark, text }, _from, { name }) do
    id = UUID.uuid4()
    modificationDate = DateTime.utc_now()
    put_task({ id, mark, text, %{ mark: modificationDate, text: modificationDate } }, { name })
    { :reply, id, { name } }
  end

  @impl true
  def handle_call(:list_tasks, _from, { name }) do
    { :reply, get_tasks(name), { name } }
  end

  def change_task_mark(task_id, mark, modificationDate, { name }) do
    on_found = fn task ->
      put_task({ task_id, mark, task.text, Map.put(task.modificationDates, :task, modificationDate) }, { name })
    end
    do_action_on_task(name, task_id, on_found)
  end

  def put_task({ id, mark, text, modificationDates }, { name }) do
    new_task = %{ mark: mark, text: text, modificationDates: modificationDates }
    agent_pids = App.ToDoList.Task.State.Manager.get_agents_pids()
    Enum.each(agent_pids, fn agent_pid -> App.ToDoList.Agent.update(agent_pid, name, id, new_task) end)
  end

  def do_action_on_task(name, id, on_found) do
    agent_pid = App.ToDoList.Task.State.Manager.get_any_local_agent_pid()
    task = App.ToDoList.Agent.get(agent_pid, name, id)
    case task do
      nil -> { :task_not_found, %{ code: "TASK_NOT_FOUND", message: "La tarea solicitada no pudo ser encontrada" } }
      _ ->  on_found.(task)
    end
  end

  def child_spec(name) do
    %{
      id: name,
      start: { __MODULE__, :start_link, name },
      restart: :transient
    }
  end

  defp get_tasks(name) do
    agent_pid = App.ToDoList.Task.State.Manager.get_any_local_agent_pid()
    App.ToDoList.Agent.get(agent_pid, name)
  end
end

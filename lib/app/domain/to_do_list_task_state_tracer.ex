defmodule App.ToDoList.Task.State.Tracer do
  use GenServer

  @to_do_list_agent_registry App.ToDoList.Agent.Registry
  @deleted_tasks_cache :deleted_tasks
  @marked_task :checked

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    { :ok, nil }
  end

  def get_any_local_agent_pid() do
    Enum.random(get_local_agents_pids())
  end

  defp get_local_agents_pids() do
    map = fn { agent_pid, _ } ->
      agent_pid
    end
    Enum.map(Registry.lookup(@to_do_list_agent_registry, App.ToDoList.Agent), map)
  end

  def get_agents_pids() do
    nodes = [ Node.self() | Node.list() ]
    map = fn node ->
      GenServer.call({__MODULE__, :"#{node}"}, :get_agents_pids)
    end
    Enum.flat_map(nodes, map)
  end

  @impl true
  def handle_call(:accept_handshake, _from, state) do
    { :reply, self(), state }
  end

  @impl true
  def handle_call(:get_agents_pids, _from, state) do
    { :reply, get_local_agents_pids(), state }
  end

  @impl true
  def handle_call(:get_any_agent_pid, _from, state) do
    { :reply, get_any_local_agent_pid(), state }
  end

  def get_local_agent_registry_pid() do
    Process.whereis(@to_do_list_agent_registry)
  end

  def sync(node) do
    local_state_map = App.ToDoList.Agent.get(get_any_local_agent_pid())
    external_state_map = App.ToDoList.Agent.get(GenServer.call({__MODULE__, :"#{node}"}, :get_any_agent_pid))

    sync_action = cond do
      local_state_map == %{} && external_state_map != %{} -> fn -> Enum.each(get_local_agents_pids(), fn agent_pid -> App.ToDoList.Agent.update(agent_pid, external_state_map) end) end
      local_state_map != %{} && external_state_map != %{} -> fn ->
        # Gather all the todo lists and iterate throught them to secure the newest record or make a deletion if is the newest operation
        to_do_lists = Enum.uniq(Map.keys(local_state_map) ++ Map.keys(external_state_map))
        Enum.each(to_do_lists, fn to_do_list ->
          local_to_do_list_map = Map.get(local_state_map, to_do_list, %{})
          external_to_do_list_map = Map.get(local_state_map, to_do_list, %{})
          to_do_list_tasks_ids = Enum.uniq(Map.keys(local_to_do_list_map) ++ Map.keys(external_to_do_list_map))

          Enum.each(to_do_list_tasks_ids, fn to_do_list_task_id ->
            local_to_do_list_task = Map.get(local_to_do_list_map, to_do_list_task_id)
            external_to_do_list_task = Map.get(external_to_do_list_map, to_do_list_task_id)

            action = cond do
              local_to_do_list_task == nil -> fn -> merge_with_no_local_task(to_do_list, to_do_list_task_id, external_to_do_list_task) end
              external_to_do_list_task != nil -> fn -> merge_with_external_task(to_do_list, to_do_list_task_id, local_to_do_list_task, external_to_do_list_task) end

              true -> fn -> :ok end
            end

            action.()
          end)
        end)
      end

      true -> fn -> :ok end
    end

    sync_action.()
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [:ok] }
    }
  end

  defp merge_with_no_local_task(list_name, task_id, external_to_do_list_task) do
    removal_date = Cachex.get(@deleted_tasks_cache, task_id)
    if external_to_do_list_task != nil and removal_date > external_to_do_list_task.modificationDates.text and removal_date > external_to_do_list_task.modificationDates.mark do
      App.ToDoList.Worker.cast(list_name, { :remove_task, task_id })
    else
      App.ToDoList.Worker.cast(list_name, { :recover_task, task_id, external_to_do_list_task.mark, external_to_do_list_task.text, external_to_do_list_task.modificationDates })
    end
  end

  defp merge_with_external_task(list_name, task_id, local_to_do_list_task, external_to_do_list_task) do
    if external_to_do_list_task.modificationsDate.text > local_to_do_list_task.modificationsDate.text do
      App.ToDoList.Worker.cast(list_name, { :edit_task, task_id, external_to_do_list_task.text, external_to_do_list_task.modificationDates.text })
    end

    if external_to_do_list_task.modificationsDate.mark > local_to_do_list_task.modificationsDate.mark do
      mark_action = if external_to_do_list_task.mark == @marked_task, do: :mark_task, else: :unmark_task
      App.ToDoList.Worker.cast(list_name, { mark_action, task_id, external_to_do_list_task.modificationDates.mark })
    end
  end
end

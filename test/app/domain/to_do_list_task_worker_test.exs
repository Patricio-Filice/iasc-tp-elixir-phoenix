defmodule App.ToDoList.Task.Worker.Test do
  use ExUnit.Case

  @to_do_list_registry App.ToDoList.Registry
  @to_do_list_agent_registry App.ToDoList.Agent.Registry
  @list_name "a list"

  describe "App.ToDoList.Task.Worker" do
    setup do
      Registry.start_link(keys: :duplicate, name: @to_do_list_registry)
      Registry.start_link(keys: :duplicate, name: @to_do_list_agent_registry)

      {Cachex, name: :deleted_tasks}
      { _, agent_pid } = App.ToDoList.Agent.start_link(:ok)
      App.ToDoList.Worker.start_link(:ok)
      App.ToDoList.Task.State.Manager.start_link(:ok)
      { _, worker_pid } = App.ToDoList.Task.Worker.start_link(@list_name)
      %{ worker_pid: worker_pid, agent_pid: agent_pid }
    end

    test "start link" do
      assert {:ok, pid} = App.ToDoList.Task.Worker.start_link(@list_name)
      assert { @list_name } = :sys.get_state(pid)
    end

    test "create task", %{ worker_pid: worker_pid, agent_pid: agent_pid } do
      task_id = GenServer.call(worker_pid, { :add_task, :unchecked, "some text" })

      task = App.ToDoList.Agent.get(agent_pid, @list_name, task_id)

      assert "some text" = task.text
      assert :unchecked = task.mark
      assert true = task.modificationDates.text >= Date.utc_today()
      assert true = task.modificationDates.mark >= Date.utc_today()
    end

    test "list tasks", %{ worker_pid: worker_pid, agent_pid: agent_pid }  do
      task_id = '1'
      App.ToDoList.Agent.update(agent_pid, @list_name, task_id, %{ text: 'No text', mark: :unchecked, modificationDates: %{} })
      :sys.get_state(agent_pid)

      assert [] = GenServer.call(@worker_pid, :list_tasks)
    end

    test "mark task", %{ worker_pid: worker_pid, agent_pid: agent_pid } do
      task_id = '1'
      App.ToDoList.Agent.update(agent_pid, @list_name, task_id, %{ text: 'No text', mark: :unchecked, modificationDates: %{} })
      :sys.get_state(agent_pid)

      GenServer.cast(worker_pid, { :mark_task, task_id })
      :sys.get_state(worker_pid)
      :sys.get_state(agent_pid)

      assert :checked = App.ToDoList.Agent.get(agent_pid, @list_name, task_id).mark
    end
  end
end

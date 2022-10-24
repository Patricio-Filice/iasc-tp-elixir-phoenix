defmodule AppWeb.TaskController do
  use AppWeb, :controller

  @unmarked_task :unchecked

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, params) do
    %{ "list_name" => list_name, "text" => text } = params
    task_id = App.ToDoList.Worker.call(list_name, { :add_task, @unmarked_task, text })
    json(conn, %{ id: task_id })
  end

  def list(conn, params) do
    %{ "list_name" => list_name } = params
    tasks = App.ToDoList.Worker.call(list_name, :list_tasks)
    map = fn { key, value } ->
      %{ id: key, mark: value.mark, text: value.text  }
    end
    json(conn, Enum.map(tasks, map))
  end

  def remove(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id } = params
    App.ToDoList.Worker.cast(list_name, { :remove_task, task_id })
    Plug.Conn.send_resp(conn, 204, "")
  end

  def update(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id, "text" => text } = params
    App.ToDoList.Worker.cast(list_name, { :edit_task, task_id, text })
    Plug.Conn.send_resp(conn, 204, "")
  end

  def mark(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id } = params
    App.ToDoList.Worker.cast(list_name, { :mark_task,  task_id })
    Plug.Conn.send_resp(conn, 204, "")
  end

  def unmark(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id } = params
    App.ToDoList.Worker.cast(list_name, { :unmark_task,  task_id })
    Plug.Conn.send_resp(conn, 204, "")
  end
end

defmodule AppWeb.TaskController do
  use AppWeb, :controller

  @unmarked_task :unchecked

  def create(conn, params) do
    %{ "list_name" => list_name, "text" => text } = params
    try_reach(
      conn,
      fn -> App.ToDoList.Worker.call(list_name, { :add_task, @unmarked_task, text }) end,
      fn task_id -> json(conn, %{ id: task_id }) end)
  end

  def list(conn, params) do
    %{ "list_name" => list_name } = params
    map = fn { key, value } ->
      %{ id: key, mark: value.mark, text: value.text  }
    end
    try_reach(
              conn,
              fn -> App.ToDoList.Worker.call(list_name, :list_tasks) end,
              fn tasks -> json(conn, Enum.map(tasks, map)) end)
  end

  def remove(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id } = params
    try_reach(conn, fn -> App.ToDoList.Worker.cast(list_name, { :remove_task, task_id }) end)
  end

  def update(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id, "text" => text } = params
    try_reach(conn, fn -> App.ToDoList.Worker.cast(list_name, { :edit_task, task_id, text }) end)
  end

  def mark(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id } = params
    try_reach(conn, fn -> App.ToDoList.Worker.cast(list_name, { :mark_task,  task_id }) end)
  end

  def unmark(conn, params) do
    %{ "list_name" => list_name, "task_id" => task_id } = params
    try_reach(conn, fn -> App.ToDoList.Worker.cast(list_name, { :unmark_task,  task_id }) end)
  end

  defp try_reach(conn, action) do
    try_reach(conn, action, fn _ -> Plug.Conn.send_resp(conn, 204, "") end)
  end

  defp try_reach(conn, action, response) do
    not_found_action = fn error ->
      conn
      |> Plug.Conn.put_status(404)
      |> json(error)
    end

    case action.() do
      { :to_do_list_not_found, error } -> not_found_action.(error)
      { :task_not_found, error } -> not_found_action.(error)
      result -> response.(result)
    end
  end
end

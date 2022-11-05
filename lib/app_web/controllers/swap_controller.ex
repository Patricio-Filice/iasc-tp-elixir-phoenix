defmodule AppWeb.SwapController do
  use AppWeb, :controller

  def create(conn, params) do
    %{ "start_list" => start_list, "end_list" => end_list, "task_id" => task_id } = params
    try_reach(conn, fn -> App.ToDoList.Worker.cast(start_list, { :swap_task, end_list, task_id }) end)
  end

  defp try_reach(conn, action) do
    not_found_action = fn error ->
      conn
      |> Plug.Conn.put_status(404)
      |> json(error)
    end

    case action.() do
      { :to_do_list_not_found, error } -> not_found_action.(error)
      { :task_not_found, error } -> not_found_action.(error)
      _ -> Plug.Conn.send_resp(conn, 204, "")
    end
  end
end

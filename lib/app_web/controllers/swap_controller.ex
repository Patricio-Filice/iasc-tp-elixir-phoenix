defmodule AppWeb.SwapController do
  use AppWeb, :controller

  def create(conn, params) do
    %{ "start_list" => start_list, "end_list" => end_list, "task_id" => task_id } = params
    App.ToDoList.Worker.cast(start_list, { :swap_task, end_list, task_id })
    Plug.Conn.send_resp(conn, 204, "")
  end
end

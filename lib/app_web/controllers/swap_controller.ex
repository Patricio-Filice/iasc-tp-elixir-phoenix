defmodule AppWeb.SwapController do
  use AppWeb, :controller

  def create(conn, params) do
    %{ "from_list_name" => _from_name, "to_list_name" => _to_name, "task_id" => _task_id } = params
    json(conn, %{ id: "1111-2222-3333-444"})
  end
end

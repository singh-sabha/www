defmodule SinghSabha.Plugs.RequireSecret do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    n8n_secret = Application.get_env(:singh_sabha, :n8n_secret)

    header_secret =
      conn
      |> get_req_header("x-n8n-secret")
      |> List.first()

    cond do
      is_nil(n8n_secret) ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "N8N_SECRET not configured"})
        |> halt()

      header_secret == n8n_secret ->
        conn

      true ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or missing x-n8n-secret header"})
        |> halt()
    end
  end
end

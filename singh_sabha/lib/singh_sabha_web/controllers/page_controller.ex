defmodule SinghSabhaWeb.PageController do
  use SinghSabhaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

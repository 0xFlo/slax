defmodule SlaxWeb.PageController do
  use SlaxWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # This is a two-argument function that takes and returns a %Plug.Conn{}. Therefore, it’s a plug. It’s that simple.
    render(conn, :home, layout: false)
  end
end

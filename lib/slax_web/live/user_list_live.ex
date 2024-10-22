defmodule SlaxWeb.UserListLive do
  use SlaxWeb, :live_view
  alias Slax.Accounts

  def mount(_params, _session, socket) do
    users = Accounts.list_users()
    {:ok, assign(socket, users: users)}
  end

  def render(assigns) do
    ~H"""
    <.header class="text-center">All Registered Users</.header>
    <.table id="user-list" rows={@users}>
      <:col :let={user} label="ID"><%= user.id %></:col>
      <:col :let={user} label="Username"><%= user.username || "No username set" %></:col>
      <:col :let={user} label="Email"><%= user.email %></:col>
      <:col :let={user} label="Confirmed At">
        <%= user.confirmed_at || "Not confirmed" %>
      </:col>
    </.table>
    """
  end
end

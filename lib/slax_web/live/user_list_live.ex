defmodule SlaxWeb.UserListLive do
  use SlaxWeb, :live_view
  alias Slax.Repo
  alias Slax.Accounts.User

  def mount(_params, _session, socket) do
    users = Repo.all(User)
    {:ok, socket |> stream(:users, users)}
  end

  def render(assigns) do
    ~H"""
    <.header class="text-center">All Registered Users</.header>
    <.table id="users" rows={@streams.users}>
      <:col :let={{_id, user}} label="ID"><%= user.id %></:col>
      <:col :let={{_id, user}} label="Username">
        <%= if user.username do %>
          <.link
            navigate={~p"/profiles/#{user.username}"}
            class="text-blue-600 hover:text-blue-700 hover:underline"
          >
            <%= user.username %>
          </.link>
        <% else %>
          <span class="text-zinc-400 text-sm">Not set</span>
        <% end %>
      </:col>
      <:col :let={{_id, user}} label="Email"><%= user.email %></:col>
      <:col :let={{_id, user}} label="Confirmed At">
        <%= user.confirmed_at || "Not confirmed" %>
      </:col>
    </.table>
    """
  end
end

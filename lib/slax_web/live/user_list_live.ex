defmodule SlaxWeb.UserListLive do
  use SlaxWeb, :live_view

  import Ecto.Query
  alias Slax.Repo
  alias Slax.Accounts.User

  def mount(_params, _session, socket) do
    users =
      from(u in User)
      |> preload(:profile)
      |> Repo.all()

    {:ok, assign(socket, users: users)}
  end

  def render(assigns) do
    ~H"""
    <.header class="text-center">All Registered Users</.header>
    <.table id="user-list" rows={@users}>
      <:col :let={user} label="ID"><%= user.id %></:col>
      <:col :let={user} label="Username">
        <%= if user.username do %>
          <.link
            navigate={~p"/profiles/#{user.username}"}
            class="text-blue-600 hover:text-blue-700 hover:underline"
          >
            @<%= user.username %>
          </.link>
        <% else %>
          <span class="text-gray-500">No username set</span>
        <% end %>
      </:col>
      <:col :let={user} label="Profile">
        <%= if user.profile do %>
          <span class="text-green-600">✓</span>
        <% else %>
          <span class="text-gray-400">-</span>
        <% end %>
      </:col>
      <:col :let={user} label="Email"><%= user.email %></:col>
      <:col :let={user} label="Confirmed At">
        <%= user.confirmed_at || "Not confirmed" %>
      </:col>
    </.table>
    """
  end
end

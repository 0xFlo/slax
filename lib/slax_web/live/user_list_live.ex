defmodule SlaxWeb.UserListLive do
  use SlaxWeb, :live_view

  alias Slax.Repo
  alias Slax.Accounts.User

  def mount(_params, _session, socket) do
    users = Repo.all(User)

    {:ok, assign(socket, users: users)}
  end

  def render(assigns) do
    ~H"""
    <.header class="text-center">All Registered Users</.header>
    <.table id="user-list" rows={@users}>
      <:col :let={user} label="ID"><%= user.id %></:col>
      <:col :let={user} label="Username">
        <%= if user.username do %>
          <%= user.username %>
        <% else %>
          <span class="text-zinc-400 text-sm">Not set</span>
        <% end %>
      </:col>
      <:col :let={user} label="Profile">
        <%= if user.bio || user.location || user.website do %>
          <.link
            navigate={~p"/profiles/#{user.username}"}
            class="text-blue-600 hover:text-blue-700 hover:underline"
          >
            @<%= user.username %>
          </.link>
        <% else %>
          <.link
            navigate={~p"/profiles/#{user.username}/edit"}
            class="text-zinc-500 hover:text-zinc-700 text-sm hover:underline"
          >
            → Create profile
          </.link>
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

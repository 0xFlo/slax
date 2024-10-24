# lib/slax_web/live/profiles/profile_live.ex
defmodule SlaxWeb.Profiles.ProfileLive do
  use SlaxWeb, :live_view
  alias Slax.Accounts

  def mount(%{"username" => username}, _session, socket) do
    user = Accounts.get_user_by_username(username)

    if user do
      {:ok,
       socket
       |> assign(:page_title, "@#{user.username}")
       |> assign(:user, user)}
    else
      {:ok,
       socket
       |> assign(:page_title, "Profile Not Found")
       |> assign(:user, nil)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8">
      <%= if @user do %>
        <div class="bg-white shadow rounded-lg p-6">
          <div class="flex items-center space-x-4 mb-6">
            <div class="flex-1">
              <h1 class="text-sm font-bold leading-none">
                @<%= @user.username %>
                <.link
                  class="font-normal text-xs text-blue-600 hover:text-blue-700"
                  navigate={~p"/profiles/#{@user.username}/edit"}
                >
                  Edit
                </.link>
              </h1>
            </div>
          </div>

          <div class="space-y-4">
            <%= if @user.bio && @user.bio != "" do %>
              <div>
                <h2 class="text-sm font-semibold text-gray-500 mb-1">Bio</h2>
                <p class="text-gray-800"><%= @user.bio %></p>
              </div>
            <% end %>

            <%= if @user.location && @user.location != "" do %>
              <div>
                <h2 class="text-sm font-semibold text-gray-500 mb-1">Location</h2>
                <p class="text-gray-800"><%= @user.location %></p>
              </div>
            <% end %>

            <%= if @user.website && @user.website != "" do %>
              <div>
                <h2 class="text-sm font-semibold text-gray-500 mb-1">Website</h2>
                <a
                  href={@user.website}
                  class="text-blue-600 hover:underline"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <%= @user.website %>
                </a>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="bg-white shadow rounded-lg p-6 text-center">
          <p class="text-gray-500">User not found.</p>
        </div>
      <% end %>
    </div>
    """
  end
end

defmodule SlaxWeb.ProfileLive do
  use SlaxWeb, :live_view
  alias Slax.Profiles

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8">
      <%= if @user do %>
        <div class="bg-white shadow rounded-lg p-6">
          <div class="flex items-center space-x-4 mb-6">
            <div class="flex-1">
              <h1 class="text-xl font-bold">@<%= @user.username %></h1>
            </div>
          </div>

          <%= if profile = @user.profile do %>
            <div class="space-y-4">
              <%= if profile.bio && profile.bio != "" do %>
                <div>
                  <h2 class="text-sm font-semibold text-gray-500 mb-1">Bio</h2>
                  <p class="text-gray-800"><%= profile.bio %></p>
                </div>
              <% end %>

              <%= if profile.location && profile.location != "" do %>
                <div>
                  <h2 class="text-sm font-semibold text-gray-500 mb-1">Location</h2>
                  <p class="text-gray-800"><%= profile.location %></p>
                </div>
              <% end %>

              <%= if profile.website && profile.website != "" do %>
                <div>
                  <h2 class="text-sm font-semibold text-gray-500 mb-1">Website</h2>
                  <a
                    href={profile.website}
                    class="text-blue-600 hover:underline"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <%= profile.website %>
                  </a>
                </div>
              <% end %>
            </div>
          <% else %>
            <p class="text-gray-500 italic">Profile not found.</p>
          <% end %>
        </div>
      <% else %>
        <div class="bg-white shadow rounded-lg p-6 text-center">
          <p class="text-gray-500">User not found.</p>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(%{"username" => username}, _session, socket) do
    user = Profiles.get_profile_by_username(username)

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
end

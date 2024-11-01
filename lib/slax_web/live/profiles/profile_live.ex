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
                <%= if @current_user && @current_user.id == @user.id do %>
                  <.link
                    class="font-normal text-xs text-blue-600 hover:text-blue-700"
                    navigate={~p"/profiles/#{@user.username}/edit"}
                  >
                    Edit
                  </.link>
                <% end %>
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

            <div class="border-t border-gray-200 pt-4">
              <h2 class="text-sm font-semibold text-gray-500 mb-2">Links</h2>
              <div class="flex flex-wrap gap-3">
                <%= if @user.website && @user.website != "" do %>
                  <a
                    href={@user.website}
                    class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <.icon name="hero-globe-alt" class="h-4 w-4" />
                    <span>Website</span>
                  </a>
                <% end %>

                <%= if @user.github_handle && @user.github_handle != "" do %>
                  <a
                    href={"https://github.com/#{@user.github_handle}"}
                    class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <.icon name="hero-code-bracket" class="h-4 w-4" />
                    <span>GitHub</span>
                  </a>
                <% end %>

                <%= if @user.twitter_handle && @user.twitter_handle != "" do %>
                  <a
                    href={"https://twitter.com/#{@user.twitter_handle}"}
                    class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <.icon name="hero-chat-bubble-left-ellipsis" class="h-4 w-4" />
                    <span>Twitter</span>
                  </a>
                <% end %>

                <%= if @user.linkedin_url && @user.linkedin_url != "" do %>
                  <a
                    href={@user.linkedin_url}
                    class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <.icon name="hero-briefcase" class="h-4 w-4" />
                    <span>LinkedIn</span>
                  </a>
                <% end %>

                <%= if @user.mastodon_handle && @user.mastodon_handle != "" do %>
                  <a
                    href={"https://#{@user.mastodon_handle}"}
                    class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <.icon name="hero-chat-bubble-left-right" class="h-4 w-4" />
                    <span>Mastodon</span>
                  </a>
                <% end %>
              </div>
            </div>
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

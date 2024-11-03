defmodule SlaxWeb.Profiles.ProfileLive do
  use SlaxWeb, :live_view
  alias Slax.Accounts
  alias Slax.Circles

  def mount(%{"username" => username}, _session, socket) do
    user = Accounts.get_user_by_username(username)

    if user do
      circles = Circles.list_user_circles(user)

      {:ok,
       socket
       |> assign(:page_title, "@#{user.username}")
       |> assign(:user, user)
       |> assign(:circles, circles)}
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
              <div class="flex justify-between items-center mb-4">
                <div>
                  <h2 class="text-sm font-semibold text-gray-900">Teaching Circles</h2>
                  <p class="text-xs text-gray-500 mt-1">
                    <%= if @current_user && @current_user.id == @user.id do %>
                      Create and manage your teaching circles
                    <% else %>
                      Circles taught by <%= @user.username %>
                    <% end %>
                  </p>
                </div>
                <%= if @current_user && @current_user.id == @user.id do %>
                  <.link
                    navigate={~p"/profiles/#{@user.username}/edit?tab=circles"}
                    class="inline-flex items-center gap-1 text-sm bg-blue-600 hover:bg-blue-700 text-white px-3 py-1.5 rounded-md"
                  >
                    <.icon name="hero-plus-small" class="w-5 h-5" />
                    <span>New Circle</span>
                  </.link>
                <% end %>
              </div>

              <div class="space-y-3">
                <%= for circle <- @circles do %>
                  <div class="group relative">
                    <div class="bg-gray-50 rounded-lg p-4 hover:bg-gray-100 transition-colors">
                      <div class="flex justify-between items-start">
                        <div class="space-y-1">
                          <div class="flex items-center gap-2">
                            <h3 class="font-medium text-gray-900"><%= circle.name %></h3>
                            <span class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-600/10">
                              <%= String.capitalize(to_string(circle.circle_type)) %>
                            </span>
                          </div>
                          <p class="text-sm text-gray-600"><%= circle.description %></p>
                          <div class="flex items-center gap-2 text-xs text-gray-500">
                            <.icon name="hero-users" class="h-4 w-4" />
                            <span><%= circle.max_students %> students max</span>
                          </div>
                        </div>
                        <%= if @current_user && @current_user.id == @user.id do %>
                          <div class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <.link
                              navigate={~p"/profiles/#{@user.username}/edit?tab=circles"}
                              class="text-xs text-gray-500 hover:text-gray-700"
                            >
                              <.icon name="hero-pencil-square" class="h-4 w-4" />
                            </.link>
                          </div>
                        <% end %>
                      </div>
                      <%= if @current_user && @current_user.id == @user.id do %>
                        <div class="mt-3 pt-3 border-t border-gray-200 flex justify-between items-center opacity-0 group-hover:opacity-100 transition-opacity">
                          <div class="text-xs text-gray-500">
                            <span class="font-medium">Invitation:</span>
                            <code class="ml-1 px-1 py-0.5 bg-gray-100 rounded font-mono">
                              <%= circle.invitation_token %>
                            </code>
                          </div>
                          <button
                            type="button"
                            class="text-xs text-blue-600 hover:text-blue-800 font-medium"
                            phx-click="copy_invitation_link"
                            phx-value-token={circle.invitation_token}
                          >
                            Copy Link
                          </button>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <%= if Enum.empty?(@circles) do %>
                  <div class="text-center py-8 px-4">
                    <div class="mx-auto h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                      <.icon name="hero-user-group" class="h-6 w-6 text-blue-600" />
                    </div>
                    <h3 class="mt-2 text-sm font-semibold text-gray-900">No circles yet</h3>
                    <p class="mt-1 text-sm text-gray-500">
                      <%= if @current_user && @current_user.id == @user.id do %>
                        Get started by creating your first teaching circle
                      <% else %>
                        <%= @user.username %> hasn't created any teaching circles yet
                      <% end %>
                    </p>
                    <%= if @current_user && @current_user.id == @user.id do %>
                      <div class="mt-6">
                        <.link
                          navigate={~p"/profiles/#{@user.username}/edit?tab=circles"}
                          class="inline-flex items-center gap-1 text-sm bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md"
                        >
                          <.icon name="hero-plus-small" class="w-5 h-5" />
                          <span>New Circle</span>
                        </.link>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

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

  def handle_event("copy_invitation_link", %{"token" => token}, socket) do
    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: token})
     |> put_flash(:info, "Invitation link copied to clipboard!")}
  end
end

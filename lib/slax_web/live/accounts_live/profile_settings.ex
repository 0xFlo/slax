defmodule SlaxWeb.AccountsLive.ProfileSettings do
  use SlaxWeb, :live_view

  alias Slax.Accounts
  alias Slax.Accounts.User
  alias Slax.Circles
  alias Slax.Circles.Circle

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header class="text-center">
        <%= @page_title %>
        <:subtitle>Update your profile and manage your circles</:subtitle>
        <:actions>
          <.link
            class="font-normal text-xs text-blue-600 hover:text-blue-700"
            navigate={~p"/profiles/#{@user.username}"}
          >
            Back
          </.link>
        </:actions>
      </.header>

      <div class="mt-8 border-b border-gray-200">
        <nav class="-mb-px flex space-x-8">
          <button
            phx-click="switch-tab"
            phx-value-tab="profile"
            class={[
              "pb-4 px-1 border-b-2 font-medium text-sm whitespace-nowrap",
              if(@current_tab == "profile",
                do: "border-blue-500 text-blue-600",
                else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              )
            ]}
          >
            Profile Settings
          </button>
          <button
            phx-click="switch-tab"
            phx-value-tab="circles"
            class={[
              "pb-4 px-1 border-b-2 font-medium text-sm whitespace-nowrap",
              if(@current_tab == "circles",
                do: "border-blue-500 text-blue-600",
                else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              )
            ]}
          >
            Circles
          </button>
        </nav>
      </div>

      <div class="mt-8">
        <%= if @current_tab == "profile" do %>
          <.simple_form
            for={@form}
            id="profile-form"
            phx-change="validate-profile"
            phx-submit="save-profile"
          >
            <.input field={@form[:bio]} type="textarea" label="Bio" phx-debounce="blur" />
            <.input field={@form[:location]} type="text" label="Location" phx-debounce="blur" />
            <.input field={@form[:website]} type="url" label="Website" phx-debounce="blur" />

            <div class="space-y-4 border-t border-gray-200 pt-4 mt-4">
              <h3 class="text-lg font-medium">Social Profiles</h3>

              <.input
                field={@form[:github_handle]}
                type="text"
                label="GitHub Username"
                placeholder="username"
                phx-debounce="blur"
              />

              <.input
                field={@form[:twitter_handle]}
                type="text"
                label="Twitter Username"
                placeholder="username (without @)"
                phx-debounce="blur"
              />

              <.input
                field={@form[:linkedin_url]}
                type="url"
                label="LinkedIn Profile URL"
                placeholder="https://www.linkedin.com/in/your-profile"
                phx-debounce="blur"
              />

              <.input
                field={@form[:mastodon_handle]}
                type="text"
                label="Mastodon Handle"
                placeholder="@username@instance.social"
                phx-debounce="blur"
              />
            </div>

            <:actions>
              <.button phx-disable-with="Saving..." class="w-full">
                Save Changes
              </.button>
            </:actions>
          </.simple_form>
        <% else %>
          <div class="space-y-6">
            <.simple_form
              :if={@show_circle_form}
              for={@circle_form}
              id="circle-form"
              phx-change="validate-circle"
              phx-submit="save-circle"
            >
              <.input field={@circle_form[:name]} type="text" label="Circle Name" required />
              <.input field={@circle_form[:description]} type="textarea" label="Description" required />
              <.input
                field={@circle_form[:max_students]}
                type="number"
                label="Maximum Students"
                value={25}
                min="1"
                max="100"
              />
              <.input
                field={@circle_form[:circle_type]}
                type="select"
                label="Circle Type"
                prompt="Select a type"
                options={[
                  {"Meditation", :meditation},
                  {"Yoga", :yoga},
                  {"Other", :other}
                ]}
              />

              <:actions>
                <.button type="button" class="w-full" phx-click="cancel-circle">
                  Cancel
                </.button>
                <.button phx-disable-with="Creating..." class="w-full">
                  Create Circle
                </.button>
              </:actions>
            </.simple_form>

            <div :if={!@show_circle_form} class="text-center">
              <button
                type="button"
                phx-click="new-circle"
                class="inline-flex items-center gap-1 px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <.icon name="hero-plus-small" class="w-5 h-5" />
                <span>Create New Circle</span>
              </button>
            </div>

            <div class="space-y-4">
              <h3 class="text-lg font-medium text-gray-900">Your Circles</h3>
              <div class="space-y-3">
                <%= for circle <- @circles do %>
                  <div class="bg-white shadow rounded-lg p-4">
                    <div class="flex justify-between items-start">
                      <div>
                        <h4 class="font-medium text-gray-900"><%= circle.name %></h4>
                        <p class="mt-1 text-sm text-gray-500"><%= circle.description %></p>
                      </div>
                      <div class="flex items-center gap-2">
                        <div class="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded-full">
                          <%= String.capitalize(to_string(circle.circle_type)) %>
                        </div>
                        <div class="text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded-full">
                          <%= circle.max_students %> max
                        </div>
                      </div>
                    </div>
                    <div class="mt-3 pt-3 border-t border-gray-200 flex justify-between items-center">
                      <div class="text-xs text-gray-500">
                        Invitation Link: <span class="font-mono"><%= circle.invitation_token %></span>
                      </div>
                      <div class="flex gap-2">
                        <button
                          type="button"
                          class="text-sm text-blue-600 hover:text-blue-800"
                          phx-click="copy-invitation"
                          phx-value-token={circle.invitation_token}
                        >
                          Copy Link
                        </button>
                        <button
                          type="button"
                          class="text-sm text-red-600 hover:text-red-800"
                          phx-click="delete-circle"
                          phx-value-id={circle.id}
                          data-confirm="Are you sure you want to delete this circle?"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  on_mount {SlaxWeb.UserAuth, :ensure_authenticated}

  def mount(%{"username" => username}, _session, socket) do
    current_user = socket.assigns.current_user

    case Accounts.get_user_by_username(username) do
      %User{id: user_id} = user when user_id == current_user.id ->
        circles = Circles.list_user_circles(user)
        changeset = User.profile_changeset(user, %{})

        {:ok,
         socket
         |> assign(:page_title, "Settings")
         |> assign(:user, user)
         |> assign(:circles, circles)
         |> assign(:current_tab, "profile")
         |> assign(:show_circle_form, false)
         |> assign(:circle_form, to_form(Circles.change_circle(%Circle{})))
         |> assign_form(changeset)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "You can only edit your own profile")
         |> push_navigate(to: ~p"/profiles/#{username}")}
    end
  end

  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :current_tab, tab)}
  end

  def handle_event("new-circle", _params, socket) do
    {:noreply, assign(socket, :show_circle_form, true)}
  end

  def handle_event("cancel-circle", _params, socket) do
    {:noreply, assign(socket, :show_circle_form, false)}
  end

  def handle_event("validate-circle", %{"circle" => circle_params}, socket) do
    changeset =
      %Circle{}
      |> Circles.change_circle(circle_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :circle_form, to_form(changeset))}
  end

  def handle_event("save-circle", %{"circle" => circle_params}, socket) do
    case Circles.create_circle(socket.assigns.current_user, circle_params) do
      {:ok, _circle} ->
        circles = Circles.list_user_circles(socket.assigns.user)

        {:noreply,
         socket
         |> assign(:circles, circles)
         |> assign(:show_circle_form, false)
         |> put_flash(:info, "Circle created successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :circle_form, to_form(changeset))}
    end
  end

  def handle_event("copy-invitation", %{"token" => token}, socket) do
    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: token})
     |> put_flash(:info, "Invitation link copied to clipboard!")}
  end

  def handle_event("delete-circle", %{"id" => id}, socket) do
    circle = Circles.get_circle!(id)

    case Circles.delete_circle(circle) do
      {:ok, _} ->
        circles = Circles.list_user_circles(socket.assigns.user)

        {:noreply,
         socket
         |> assign(:circles, circles)
         |> put_flash(:info, "Circle deleted successfully!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete circle")}
    end
  end

  def handle_event("validate-profile", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> User.profile_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save-profile", %{"user" => user_params}, socket) do
    current_user = socket.assigns.current_user
    user = socket.assigns.user

    case Accounts.update_user_profile(current_user, user, user_params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> push_navigate(to: ~p"/profiles/#{updated_user.username}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to edit this profile")
         |> push_navigate(to: ~p"/profiles/#{user.username}")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end

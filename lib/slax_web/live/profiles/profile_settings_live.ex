defmodule SlaxWeb.Profiles.ProfileSettingsLive do
  use SlaxWeb, :live_view

  alias Slax.Accounts
  alias Slax.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header class="text-center">
        <%= @page_title %>
        <:subtitle>Update your public profile information</:subtitle>
        <:actions>
          <.link
            class="font-normal text-xs text-blue-600 hover:text-blue-700"
            navigate={~p"/profiles/#{@user.username}"}
          >
            Back
          </.link>
        </:actions>
      </.header>

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

      <.back navigate={~p"/profiles/#{@user.username}"}>Back to profile</.back>
    </div>
    """
  end

  on_mount {SlaxWeb.UserAuth, :ensure_authenticated}

  def mount(%{"username" => username}, _session, socket) do
    current_user = socket.assigns.current_user

    case Accounts.get_user_by_username(username) do
      %User{id: user_id} = user when user_id == current_user.id ->
        changeset = User.profile_changeset(user, %{})

        {:ok,
         socket
         |> assign(:page_title, "Edit Profile")
         |> assign(:user, user)
         |> assign_form(changeset)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "You can only edit your own profile")
         |> push_navigate(to: ~p"/profiles/#{username}")}
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

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

  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/")}

      user ->
        changeset = User.profile_changeset(user, %{})

        socket =
          socket
          |> assign(:page_title, "Edit Profile")
          |> assign(:user, user)
          |> assign_form(changeset)

        {:ok, socket}
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
    case Accounts.update_user_profile(socket.assigns.user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> push_navigate(to: ~p"/profiles/#{user.username}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end

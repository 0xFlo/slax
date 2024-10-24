defmodule SlaxWeb.Profiles.ProfileSettingsLive do
  use SlaxWeb, :live_view
  alias Slax.Accounts

  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/")}

      user ->
        {:ok,
         socket
         |> assign(:page_title, "Edit Profile")
         |> assign(:user, user)
         |> assign(:form, to_form(User.profile_changeset(user, %{})))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> User.profile_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_profile(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> push_navigate(to: ~p"/profiles/#{socket.assigns.user.username}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8">
      <.header class="text-center">
        Edit Profile
        <:subtitle>Update your public profile information</:subtitle>
      </.header>

      <.simple_form for={@form} id="profile_form" phx-change="validate" phx-submit="save">
        <.input field={@form[:bio]} type="textarea" label="Bio" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:website]} type="url" label="Website" />

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
end

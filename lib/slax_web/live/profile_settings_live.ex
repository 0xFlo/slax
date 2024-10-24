defmodule SlaxWeb.ProfileSettingsLive do
  use SlaxWeb, :live_view
  alias Slax.Profiles
  alias Slax.Accounts.Profile

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
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    {:ok, profile} = Profiles.ensure_profile_exists(user)

    {:ok,
     socket
     |> assign(:page_title, "Edit Profile")
     |> assign(:profile, profile)
     |> assign(:form, to_form(Profile.changeset(profile, %{})))}
  end

  def handle_event("validate", %{"profile" => profile_params}, socket) do
    changeset =
      socket.assigns.profile
      |> Profile.changeset(profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"profile" => profile_params}, socket) do
    case Profiles.update_profile(socket.assigns.profile, profile_params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> assign(:profile, profile)
         |> assign(:form, to_form(Profile.changeset(profile, %{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end

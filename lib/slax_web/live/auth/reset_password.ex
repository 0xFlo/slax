defmodule SlaxWeb.Live.Auth.ResetPassword do
  use SlaxWeb, :live_view
  alias Slax.Accounts

  def mount(params, _session, socket) do
    socket =
      case params do
        # Reset password form with token
        %{"token" => token} ->
          socket = assign_user_and_token(socket, token)

          form_source =
            case socket.assigns do
              %{user: user} -> Accounts.change_user_password(user)
              _ -> %{}
            end

          assign(socket,
            page_title: "Reset Password",
            form: to_form(form_source)
          )

        # Initial forgot password form
        _ ->
          assign(socket,
            page_title: "Forgot your password?",
            form: to_form(%{}, as: "user")
          )
      end

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <div class="mx-auto w-96 mt-16">
      <.header class="text-center">
        <%= @page_title %>
        <:subtitle>We'll send a password reset link to your inbox</:subtitle>
      </.header>

      <.simple_form for={@form} id="reset_password_form" phx-submit="send_reset_email">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Send password reset instructions
          </.button>
        </:actions>
      </.simple_form>
      <p class="text-center text-sm mt-4">
        <.link href={~p"/users/register"}>Register</.link>
        | <.link href={~p"/users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="mx-auto w-96 mt-16">
      <.header class="text-center">Reset Password</.header>

      <.simple_form
        for={@form}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.error :if={@form.errors != []}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input
          field={@form[:password]}
          type="password"
          label="New password"
          required
          phx-debounce="300"
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          required
          phx-debounce="300"
        />
        <:actions>
          <.button phx-disable-with="Resetting..." class="w-full">Reset Password</.button>
        </:actions>
      </.simple_form>

      <p class="text-center text-sm mt-4">
        <.link href={~p"/users/register"}>Register</.link>
        | <.link href={~p"/users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def handle_event("send_reset_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_authenticated_user(email, "") do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/users/log_in")}
  end

  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate)))}
  end

  defp assign_user_and_token(socket, token) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end
end

defmodule SlaxWeb.Live.Auth.Confirmation do
  use SlaxWeb, :live_view
  alias Slax.Accounts

  def mount(params, _session, socket) do
    socket =
      case params do
        # Confirmation with token
        %{"token" => token} ->
          assign(socket,
            page_title: "Confirm Account",
            form: to_form(%{"token" => token}, as: "user")
          )

        # Request new confirmation instructions
        _ ->
          assign(socket,
            page_title: "Resend confirmation instructions",
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
        <:subtitle>We'll send a new confirmation link to your inbox</:subtitle>
      </.header>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Resend confirmation instructions
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={~p"/users/register"}>Register</.link>
        | <.link href={~p"/users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="mx-auto w-96 mt-16">
      <.header class="text-center">Confirm Account</.header>

      <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
        <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
        <:actions>
          <.button phx-disable-with="Confirming..." class="w-full">Confirm my account</.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={~p"/users/register"}>Register</.link>
        | <.link href={~p"/users/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_authenticated_user(email, "") do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end

  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end

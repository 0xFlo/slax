# lib/slax_web/live/circle_live/new.ex
defmodule SlaxWeb.CircleLive.New do
  use SlaxWeb, :live_view
  alias Slax.Circles
  alias Slax.Circles.Circle

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create New Circle")
     |> assign_form(Circles.change_circle(%Circle{}))}
  end

  def handle_event("validate", %{"circle" => circle_params}, socket) do
    changeset =
      %Circle{}
      |> Circles.change_circle(circle_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"circle" => circle_params}, socket) do
    case Circles.create_circle(socket.assigns.current_user, circle_params) do
      {:ok, _circle} ->
        {:noreply,
         socket
         |> put_flash(:info, "Circle created successfully!")
         |> push_navigate(to: ~p"/profiles/#{socket.assigns.current_user.username}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <.header class="text-center">
        Create New Circle
        <:subtitle>Create a private circle for your community</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="circle-form"
        phx-change="validate"
        phx-submit="save"
        class="space-y-8 mt-8"
      >
        <.input field={@form[:name]} type="text" label="Circle Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" required />
        <.input
          field={@form[:max_students]}
          type="number"
          label="Maximum Students"
          value={25}
          min="1"
          max="100"
        />
        <.input
          field={@form[:circle_type]}
          type="select"
          label="Circle Type"
          options={[
            {"Meditation", :meditation},
            {"Yoga", :yoga},
            {"Other", :other}
          ]}
        />

        <:actions>
          <.button phx-disable-with="Creating..." class="w-full">
            Create Circle
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end

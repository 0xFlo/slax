defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Accounts.User
  alias Slax.Chat
  alias Slax.Chat.{Message, Room}

  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <!-- Ensures the entire app container uses full height -->
      <.sidebar rooms={@rooms} current_room={@room} />
      <div class="flex flex-col flex-grow shadow-lg h-full">
        <.room_header room={@room} hide_topic?={@hide_topic?} />
        <div
          id="room-messages"
          class="flex flex-col flex-grow overflow-y-auto h-full"
          phx-hook="RoomMessages"
          phx-update="stream"
        >
          <.message
            :for={{dom_id, message} <- @streams.messages}
            current_user={@current_user}
            dom_id={dom_id}
            message={message}
          />
        </div>
        <.message_form room={@room} form={@new_message_form} />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Slax.PubSub, "chat_rooms")
    end

    rooms = Chat.list_rooms()

    {:ok,
     socket
     |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
     |> stream(:messages, [])
     |> assign(rooms: rooms)
     |> assign_message_form(Chat.change_message(%Message{}))
     |> push_event("scroll_messages_to_bottom", %{})}
  end

  def handle_params(params, _session, socket) do
    if socket.assigns[:room], do: Chat.unsubscribe_from_room(socket.assigns.room)

    room = fetch_room(params)
    messages = Chat.list_messages_in_room(room)

    Chat.subscribe_to_room(room)

    {:noreply,
     socket
     |> assign(
       hide_topic?: false,
       page_title: "#" <> room.name,
       room: room
     )
     |> stream(:messages, messages, reset: true)
     |> assign_message_form(Chat.change_message(%Message{}))}
  end

  # Group all handle_event/3 clauses together
  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    socket =
      case Chat.create_message(room, message_params, current_user) do
        {:ok, _message} ->
          assign_message_form(socket, Chat.change_message(%Message{}))

        {:error, changeset} ->
          assign_message_form(socket, changeset)
      end

    {:noreply, socket}
  end

  def handle_event("validate-message", %{"message" => message_params}, socket) do
    changeset = Chat.change_message(%Message{}, message_params)
    {:noreply, assign_message_form(socket, changeset)}
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, update(socket, :hide_topic?, &(!&1))}
  end

  def handle_event("delete-message", %{"id" => id}, socket) do
    Chat.delete_message_by_id(id, socket.assigns.current_user)
    {:noreply, socket}
  end

  # Group all handle_info/2 clauses together
  def handle_info({:new_message, message}, socket) do
    socket =
      socket
      |> stream_insert(:messages, message)
      |> push_event("scroll_messages_to_bottom", %{})

    {:noreply, socket}
  end

  def handle_info({:message_deleted, message}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end

  # Components
  attr :rooms, :list, required: true
  attr :current_room, Room, required: true

  defp sidebar(assigns) do
    ~H"""
    <div class="flex flex-col flex-shrink-0 w-64 bg-slate-100">
      <div class="flex justify-between items-center flex-shrink-0 h-16 border-b border-slate-300 px-4">
        <h1 class="text-lg font-bold text-gray-800">Slax</h1>
      </div>
      <div class="mt-4 overflow-auto">
        <div class="flex items-center h-8 px-3 group">
          <span class="ml-2 leading-none font-medium text-sm">Rooms</span>
        </div>
        <div id="rooms-list">
          <.room_link :for={room <- @rooms} room={room} active={room.id == @current_room.id} />
        </div>
      </div>
    </div>
    """
  end

  attr :room, Room, required: true
  attr :hide_topic?, :boolean, required: true

  defp room_header(assigns) do
    ~H"""
    <div class="flex justify-between items-center flex-shrink-0 h-16 bg-white border-b border-slate-300 px-4">
      <h1 class="text-sm font-bold leading-none">
        #<%= @room.name %>
        <.link
          class="font-normal text-xs text-blue-600 hover:text-blue-700"
          navigate={~p"/rooms/#{@room}/edit"}
        >
          Edit
        </.link>
      </h1>
      <div class="text-xs leading-none h-3.5" phx-click="toggle-topic">
        <%= if @hide_topic? do %>
          <span class="text-slate-600">[Topic hidden]</span>
        <% else %>
          <%= @room.topic %>
        <% end %>
      </div>
    </div>
    """
  end

  attr :room, Room, required: true
  attr :form, :any, required: true

  def message_form(assigns) do
    ~H"""
    <div class="h-12 bg-white px-4 pb-4">
      <.form
        id="new-message-form"
        for={@form}
        phx-change="validate-message"
        phx-submit="submit-message"
        class="flex items-center border-2 border-slate-300 rounded-sm p-1"
      >
        <textarea
          class="flex-grow text-sm px-3 border-l border-slate-300 mx-1 resize-none"
          cols=""
          id="chat-message-textarea"
          name={@form[:body].name}
          phx-debounce
          phx-hook="ChatMessageTextarea"
          placeholder={"Message ##{@room.name}"}
          rows="1"
        ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:body].value) %></textarea>
        <button class="flex-shrink flex items-center justify-center h-6 w-6 rounded hover:bg-slate-200">
          <.icon name="hero-paper-airplane" class="h-4 w-4" />
        </button>
      </.form>
    </div>
    """
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true

  defp room_link(assigns) do
    ~H"""
    <.link
      class={[
        "flex items-center h-8 text-sm pl-8 pr-3",
        (@active && "bg-slate-300") || "hover:bg-slate-300"
      ]}
      patch={~p"/rooms/#{@room}"}
    >
      <.icon name="hero-hashtag" class="h-4 w-4" />
      <span class={["ml-2 leading-none", @active && "font-bold"]}>
        <%= @room.name %>
      </span>
    </.link>
    """
  end

  attr :current_user, User, required: true
  attr :dom_id, :string, required: true
  attr :message, Message, required: true

  defp message(assigns) do
    ~H"""
    <div id={@dom_id} class="group relative flex px-4 py-3">
      <button
        :if={@current_user.id == @message.user_id}
        class="absolute top-4 right-4 text-red-500 hover:text-red-800 cursor-pointer hidden group-hover:block"
        data-confirm="Are you sure?"
        phx-click="delete-message"
        phx-value-id={@message.id}
      >
        <.icon name="hero-trash" class="h-4 w-4" />
      </button>
      <div class="h-10 w-10 rounded flex-shrink-0 bg-slate-300"></div>
      <div class="ml-2">
        <div class="-mt-1">
          <.link class="text-sm font-semibold hover:underline">
            <span><%= username(@message.user) %></span>
          </.link>
          <span class="ml-1 text-xs text-gray-500"><%= message_timestamp(@message) %></span>

          <p class="text-sm"><%= @message.body %></p>
        </div>
      </div>
    </div>
    """
  end

  # Private helper functions
  defp username(user) do
    user.email |> String.split("@") |> List.first() |> String.capitalize()
  end

  defp assign_message_form(socket, changeset) do
    assign(socket, :new_message_form, to_form(changeset))
  end

  defp message_timestamp(message) do
    message.inserted_at
    |> Timex.format!("%-l:%M %p", :strftime)
  end

  defp fetch_room(params) do
    case Map.fetch(params, "id") do
      {:ok, id} -> Chat.get_room!(id)
      :error -> Chat.get_first_room!()
    end
  end
end

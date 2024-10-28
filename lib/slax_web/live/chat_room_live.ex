# lib/slax_web/live/chat_room_live.ex
defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view
  alias Slax.Chat
  alias Slax.Chat.{Message, Room}

  # Render the main LiveView template
  def render(assigns) do
    ~H"""
    <div class="flex h-full">
      <.sidebar rooms={@rooms} current_room={@room} />
      <.main_content
        room={@room}
        hide_topic?={@hide_topic?}
        messages={@messages}
        new_message_form={@new_message_form}
      />
    </div>
    """
  end

  # Define the main sidebar component
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

  # Define the main content component, including the room header and messages list
  attr :room, Room, required: true
  attr :hide_topic?, :boolean, required: true
  attr :messages, :list, required: true
  attr :new_message_form, :any, required: true

  defp main_content(assigns) do
    ~H"""
    <div class="flex flex-col flex-grow shadow-lg">
      <.room_header room={@room} hide_topic?={@hide_topic?} />
      <div class="flex flex-col flex-grow overflow-auto">
        <.message :for={message <- @messages} message={message} />
      </div>
      <div class="h-12 bg-white px-4 pb-4">
        <.form
          id="new-message-form"
          for={@new_message_form}
          phx-change="validate-message"
          phx-submit="submit-message"
          class="flex items-center border-2 border-slate-300 rounded-sm p-1"
        >
          <textarea
            class="flex-grow text-sm px-3 border-l border-slate-300 mx-1 resize-none"
            cols=""
            id="chat-message-textarea"
            name={@new_message_form[:body].name}
            placeholder={"Message ##{@room.name}"}
            phx-debounce
            rows="1"
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @new_message_form[:body].value) %></textarea>
          <button class="flex-shrink flex items-center justify-center h-6 w-6 rounded hover:bg-slate-200">
            <.icon name="hero-paper-airplane" class="h-4 w-4" />
          </button>
        </.form>
      </div>
    </div>
    """
  end

  # Define the room header with toggle topic functionality
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

  # Define the room link component for the sidebar
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

  # Define the message component for rendering each individual message
  attr :message, Message, required: true

  defp message(assigns) do
    ~H"""
    <div class="relative flex px-4 py-3">
      <div class="h-10 w-10 rounded flex-shrink-0 bg-slate-300"></div>
      <div class="ml-2">
        <div class="-mt-1">
          <.link class="text-sm font-semibold hover:underline">
            <span><%= username(@message.user) %></span>
          </.link>
          <p class="text-sm"><%= @message.body %></p>
        </div>
      </div>
    </div>
    """
  end

  defp username(user) do
    user.email |> String.split("@") |> List.first() |> String.capitalize()
  end

  # Mount function to initialize the rooms list
  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms()

    {:ok,
     socket
     |> assign(rooms: rooms)
     |> assign_message_form(Chat.change_message(%Message{}))}
  end

  # Handle route parameters to fetch the selected room and its messages
  def handle_params(params, _session, socket) do
    room = fetch_room(params)
    messages = Chat.list_messages_in_room(room)

    {:noreply,
     socket
     |> assign(
       hide_topic?: false,
       messages: messages,
       page_title: "#" <> room.name,
       room: room
     )
     |> assign_message_form(Chat.change_message(%Message{}))}
  end

  defp assign_message_form(socket, changeset) do
    assign(socket, :new_message_form, to_form(changeset))
  end

  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    socket =
      case Chat.create_message(room, message_params, current_user) do
        {:ok, message} ->
          socket
          |> update(:messages, &(&1 ++ [message]))
          |> assign_message_form(Chat.change_message(%Message{}))

        {:error, changeset} ->
          assign_message_form(socket, changeset)
      end

    {:noreply, socket}
  end

  # Handle toggling the topic visibility
  def handle_event("toggle-topic", _params, socket) do
    {:noreply, update(socket, :hide_topic?, &(!&1))}
  end

  # Add the validate-message event handler:
  def handle_event("validate-message", %{"message" => message_params}, socket) do
    changeset = Chat.change_message(%Message{}, message_params)
    {:noreply, assign_message_form(socket, changeset)}
  end

  # Helper function to fetch the room by ID or get the first room
  defp fetch_room(params) do
    case Map.fetch(params, "id") do
      {:ok, id} -> Chat.get_room!(id)
      :error -> Chat.get_first_room!()
    end
  end
end

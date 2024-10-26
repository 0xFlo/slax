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
      <.main_content room={@room} hide_topic?={@hide_topic?} messages={@messages} />
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

  defp main_content(assigns) do
    ~H"""
    <div class="flex flex-col flex-grow shadow-lg">
      <.room_header room={@room} hide_topic?={@hide_topic?} />
      <div class="flex flex-col flex-grow overflow-auto">
        <.message :for={message <- @messages} message={message} />
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
            <span>User</span>
          </.link>
          <p class="text-sm"><%= @message.body %></p>
        </div>
      </div>
    </div>
    """
  end

  # Mount function to initialize the rooms list
  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms()
    {:ok, assign(socket, rooms: rooms)}
  end

  # Handle route parameters to fetch the selected room and its messages
  def handle_params(params, _session, socket) do
    room = fetch_room(params)
    messages = Chat.list_messages_in_room(room)

    {:noreply,
     assign(socket,
       hide_topic?: false,
       messages: messages,
       page_title: "#" <> room.name,
       room: room
     )}
  end

  # Handle toggling the topic visibility
  def handle_event("toggle-topic", _params, socket) do
    {:noreply, update(socket, :hide_topic?, &(!&1))}
  end

  # Helper function to fetch the room by ID or get the first room
  defp fetch_room(params) do
    case Map.fetch(params, "id") do
      {:ok, id} -> Chat.get_room!(id)
      :error -> Chat.get_first_room!()
    end
  end
end

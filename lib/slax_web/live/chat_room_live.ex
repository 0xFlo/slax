defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Accounts
  alias Slax.Accounts.User
  alias Slax.Chat
  alias Slax.Chat.{Message, Room}
  alias SlaxWeb.OnlineUsers

  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <.sidebar rooms={@rooms} current_room={@room} users={@users} online_users={@online_users} />
      <div class="flex flex-col flex-grow shadow-lg h-full">
        <.room_header room={@room} hide_topic?={@hide_topic?} joined?={@joined?} />
        <div
          :if={!@joined?}
          class="flex justify-around mx-5 mb-5 p-6 bg-slate-100 border-slate-300 border rounded-lg"
        >
          <div class="max-w-3-xl text-center">
            <div class="mb-4">
              <h1 class="text-xl font-semibold">#<%= @room.name %></h1>
              <p :if={@room.topic} class="text-sm mt-1 text-gray-600"><%= @room.topic %></p>
            </div>
            <div class="flex items-center justify-around">
              <button
                phx-click="join-room"
                class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-500"
              >
                Join Room
              </button>
            </div>
            <div class="mt-4">
              <.link
                navigate={~p"/rooms"}
                href="#"
                class="text-sm text-slate-500 underline hover:text-slate-600"
              >
                Back to All Rooms
              </.link>
            </div>
          </div>
        </div>
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
        <.message_form room={@room} form={@new_message_form} joined?={@joined?} />
      </div>
    </div>
    <.modal id="new-room-modal">
      <.header>New chat room</.header>
      <.simple_form
        for={@new_room_form}
        id="room-form"
        phx-change="validate-room"
        phx-submit="save-room"
      >
        <.input field={@new_room_form[:name]} type="text" label="Name" phx-debounce />
        <.input field={@new_room_form[:topic]} type="text" label="Topic" phx-debounce />
        <:actions>
          <.button phx-disable-with="Saving..." class="w-full">Save</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    rooms = Chat.list_joined_rooms(socket.assigns.current_user)
    users = Accounts.list_users()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Slax.PubSub, "chat_rooms")
      OnlineUsers.track(self(), socket.assigns.current_user)
    end

    OnlineUsers.subscribe()

    {:ok,
     socket
     |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
     |> stream(:messages, [])
     |> assign(rooms: rooms)
     |> assign(users: users)
     |> assign(online_users: OnlineUsers.list())
     |> assign(joined?: false)
     |> assign_room_form(Chat.change_room(%Room{}))
     |> assign_message_form(Chat.change_message(%Message{}))
     |> push_event("scroll_messages_to_bottom", %{})}
  end

  def handle_params(params, _session, socket) do
    if socket.assigns[:room], do: Chat.unsubscribe_from_room(socket.assigns.room)

    room = fetch_room(params)
    messages = Chat.list_messages_in_room(room)

    # Get the joined? status
    joined? = Chat.joined?(room, socket.assigns.current_user)

    Chat.subscribe_to_room(room)

    {:noreply,
     socket
     |> assign(
       hide_topic?: false,
       # Add this line
       joined?: joined?,
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
      if Chat.joined?(room, current_user) do
        case Chat.create_message(room, message_params, current_user) do
          {:ok, _message} ->
            assign_message_form(socket, Chat.change_message(%Message{}))

          {:error, changeset} ->
            assign_message_form(socket, changeset)
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("join-room", _, socket) do
    current_user = socket.assigns.current_user
    Chat.join_room!(socket.assigns.room, current_user)
    Chat.subscribe_to_room(socket.assigns.room)
    socket = assign(socket, joined?: true, rooms: Chat.list_joined_rooms(current_user))
    {:noreply, socket}
  end

  def handle_event("delete-message", %{"id" => id}, socket) do
    Chat.delete_message_by_id(id, socket.assigns.current_user)
    {:noreply, socket}
  end

  def handle_event("validate-message", %{"message" => message_params}, socket) do
    changeset = Chat.change_message(%Message{}, message_params)
    {:noreply, assign_message_form(socket, changeset)}
  end

  def handle_event("validate-room", %{"room" => room_params}, socket) do
    changeset =
      socket.assigns.room
      |> Chat.change_room(room_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_room_form(socket, changeset)}
  end

  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.create_room(room_params) do
      {:ok, room} ->
        Chat.join_room!(room, socket.assigns.current_user)

        {:noreply,
         socket
         |> put_flash(:info, "Created room")
         |> push_navigate(to: ~p"/rooms/#{room}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_room_form(socket, changeset)}
    end
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, update(socket, :hide_topic?, &(!&1))}
  end

  def handle_info({:new_message, message}, socket) do
    socket =
      socket
      |> stream_insert(:messages, message)
      |> push_event("scroll_messages_to_bottom", %{})

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    online_users = OnlineUsers.update(socket.assigns.online_users, diff)

    {:noreply, assign(socket, online_users: online_users)}
  end

  def handle_info({:message_deleted, message}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end

  # Components
  attr :rooms, :list, required: true
  attr :current_room, Room, required: true
  attr :users, :list, required: true
  attr :online_users, :list, required: true

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
          <button class="group relative flex items-center h-8 text-sm pl-8 pr-3 hover:bg-slate-300 cursor-pointer w-full">
            <.icon name="hero-plus" class="h-4 w-4 relative top-px" />
            <span class="ml-2 leading-none">Add rooms</span>
            <div class="hidden group-focus:block cursor-default absolute top-8 right-2 bg-white border-slate-200 border py-3 rounded-lg">
              <div class="w-full text-left">
                <div class="hover:bg-sky-600">
                  <div
                    class="cursor-pointer whitespace-nowrap text-gray-800 hover:text-white px-6 py-1 block"
                    phx-click={show_modal("new-room-modal")}
                  >
                    Create a new room
                  </div>
                </div>
                <div class="hover:bg-sky-600">
                  <div
                    phx-click={JS.navigate(~p"/rooms")}
                    class="cursor-pointer whitespace-nowrap text-gray-800 hover:text-white px-6 py-1"
                  >
                    Browse rooms
                  </div>
                </div>
              </div>
            </div>
          </button>
        </div>
        <div class="mt-4">
          <div class="flex items-center h-8 px-3 group">
            <div class="flex items-center flex-grow focus:outline-none">
              <span class="ml-2 leading-none font-medium text-sm">Users</span>
            </div>
          </div>
          <div id="users-list">
            <.user
              :for={user <- @users}
              user={user}
              online={OnlineUsers.online?(@online_users, user.id)}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :count, :integer, required: true

  defp unread_message_counter(assigns) do
    ~H"""
    <span
      :if={@count > 0}
      class="flex items-center justify-center bg-blue-500 rounded-full font-medium h-5 px-2 ml-auto text-xs text-white"
    >
      <%= @count %>
    </span>
    """
  end

  attr :user, User, required: true
  attr :online, :boolean, default: false

  defp user(assigns) do
    ~H"""
    <.link class="flex items-center h-8 hover:bg-gray-300 text-sm pl-8 pr-3" href="#">
      <div class="flex justify-center w-4">
        <%= if @online do %>
          <span class="w-2 h-2 rounded-full bg-blue-500"></span>
        <% else %>
          <span class="w-2 h-2 rounded-full border-2 border-gray-500"></span>
        <% end %>
      </div>
      <span class="ml-2 leading-none">@<%= @user.username %></span>
    </.link>
    """
  end

  attr :room, Room, required: true
  attr :hide_topic?, :boolean, required: true
  attr :joined?, :boolean, required: true

  defp room_header(assigns) do
    ~H"""
    <div class="flex justify-between items-center flex-shrink-0 h-16 bg-white border-b border-slate-300 px-4">
      <h1 class="text-sm font-bold leading-none">
        #<%= @room.name %>
        <.link
          :if={@joined?}
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
  # Add this line
  attr :joined?, :boolean, required: true

  def message_form(assigns) do
    ~H"""
    <div :if={@joined?} class="h-12 bg-white px-4 pb-4">
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
      <img class="h-10 w-10 rounded flex-shrink-0" src={~p"/images/one_ring.jpg"} />
      <div class="ml-2">
        <div class="-mt-1">
          <.link
            navigate={~p"/profiles/#{@message.user.username}"}
            class="text-sm font-semibold hover:underline"
          >
            @<%= @message.user.username %>
          </.link>
          <span class="ml-1 text-xs text-gray-500"><%= message_timestamp(@message) %></span>

          <p class="text-sm"><%= @message.body %></p>
        </div>
      </div>
    </div>
    """
  end

  defp assign_room_form(socket, changeset) do
    assign(socket, :new_room_form, to_form(changeset))
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

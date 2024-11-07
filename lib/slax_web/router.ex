defmodule SlaxWeb.Router do
  use SlaxWeb, :router

  import SlaxWeb.Live.Auth.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SlaxWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", SlaxWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{SlaxWeb.Live.Auth.UserAuth, :mount_current_user}] do
      # Public profile viewing
      live "/profiles", Live.Users.ProfileList, :index
      live "/profiles/:username", Live.Users.ProfileLive, :show
      get "/home", PageController, :home
    end

    # Account confirmation routes
    live_session :account_confirmation,
      on_mount: [{SlaxWeb.Live.Auth.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", Live.Auth.Confirmation, :edit
      live "/users/confirm", Live.Auth.Confirmation, :new
    end

    delete "/users/log_out", Live.Auth.SessionController, :delete
  end

  # Routes that require authentication but no specific user
  scope "/", SlaxWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated_general,
      on_mount: [{SlaxWeb.Live.Auth.UserAuth, :ensure_authenticated}] do
      # Chat rooms
      live "/", Live.Chat.ChatRoomLive, :index
      live "/rooms", Live.Chat.ChatRoomIndex, :index
      live "/rooms/:id", Live.Chat.ChatRoomLive, :show
      live "/rooms/:id/edit", Live.Chat.ChatRoomEdit, :edit

      live "/circles/new", Live.Circles.New, :new
    end
  end

  # Routes that require authentication AND specific user verification
  scope "/", SlaxWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated_user_specific,
      on_mount: [{SlaxWeb.Live.Auth.UserAuth, :ensure_authenticated}] do
      # User-specific routes
      live "/users/settings", Live.Users.AccountSettings, :edit
      live "/users/settings/confirm_email/:token", Live.Users.AccountSettings, :confirm_email
      live "/profiles/:username/edit", Live.Users.ProfileSettings, :edit
    end
  end

  # Login/registration routes
  scope "/", SlaxWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :unauthenticated,
      on_mount: [{SlaxWeb.Live.Auth.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", Live.Auth.Registration, :new
      live "/users/log_in", Live.Auth.Login, :new
      live "/users/reset_password", Live.Auth.ResetPassword, :new
      live "/users/reset_password/:token", Live.Auth.ResetPassword, :edit
    end

    post "/users/log_in", Live.Auth.SessionController, :create
  end

  # Development-only routes
  if Application.compile_env(:slax, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SlaxWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

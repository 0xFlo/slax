defmodule SlaxWeb.Router do
  use SlaxWeb, :router

  import SlaxWeb.UserAuth

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

  # Unprotected routes that don't require authentication
  scope "/", SlaxWeb do
    pipe_through :browser

    # Public profile viewing
    live_session :public_profiles,
      on_mount: [{SlaxWeb.UserAuth, :mount_current_user}] do
      live "/profiles", UserListLive, :index
      live "/profiles/:username", Profiles.ProfileLive, :show
    end

    # Account confirmation routes
    live_session :account_confirmation,
      on_mount: [{SlaxWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end

    delete "/users/log_out", UserSessionController, :delete
  end

  # Routes that require authentication
  scope "/", SlaxWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{SlaxWeb.UserAuth, :ensure_authenticated}] do
      # Chat rooms - now protected
      live "/", ChatRoomLive, :index
      live "/rooms/:id", ChatRoomLive, :show
      live "/rooms/:id/edit", ChatRoomLive.Edit, :edit

      # User settings and profile management
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/profiles/:username/edit", Profiles.ProfileSettingsLive, :edit
    end
  end

  # Routes accessible only to non-authenticated users
  scope "/", SlaxWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :unauthenticated,
      on_mount: [{SlaxWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
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

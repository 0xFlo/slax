import Config

# Configure your database
config :slax, Slax.Repo,
  database: "priv/repo/slax_dev.db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 5,
  busy_timeout: 5000

config :slax, SlaxWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "iGCb4HuivgeghllaPk5hvihz/+LciYjbqQl7adxlkWyrw1GhP0wFXwsd7KcXL7yL",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:slax, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:slax, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :slax, SlaxWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/slax_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :slax, dev_routes: true
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false

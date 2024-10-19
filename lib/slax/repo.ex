# lib/slax/repo.ex
defmodule Slax.Repo do
  use Ecto.Repo,
    otp_app: :slax,
    adapter: Ecto.Adapters.SQLite3
end

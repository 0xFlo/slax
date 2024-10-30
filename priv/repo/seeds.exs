alias Slax.Accounts
alias Slax.Chat
alias Slax.Repo

# Create users
names = [
  "Aragorn",
  "Boromir",
  "Elrond",
  "Frodo",
  "Gimli",
  "Legolas"
]

# Password meets all requirements:
# - At least 12 characters
# - Contains uppercase
# - Contains number
# - Contains special character
pw = "Fellowship_123!"

# Create users with error handling
for name <- names do
  email = (name |> String.downcase()) <> "@fellowship.me"
  username = String.downcase(name)

  case Accounts.register_user(%{
         email: email,
         password: pw,
         username: username
       }) do
    {:ok, user} ->
      # Confirm the user's email
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Ecto.Changeset.change(user, confirmed_at: now)
      |> Repo.update!()

    {:error, changeset} ->
      IO.puts("Failed to create user #{username}:")
      IO.inspect(changeset.errors)
  end
end

# Fetch created users
elrond = Accounts.get_user_by_email("elrond@fellowship.me")
aragorn = Accounts.get_user_by_email("aragorn@fellowship.me")
boromir = Accounts.get_user_by_email("boromir@fellowship.me")

# Clean up existing data
Repo.delete_all(Chat.Message)
Repo.delete_all(Chat.Room)

# Create room with error handling
case Chat.create_room(%{
       name: "council-of-elrond",
       topic: "What to do with this ring?"
     }) do
  {:ok, room} ->
    # Create messages
    messages = [
      {elrond,
       "Strangers from distant lands, friends of old. You have been summoned here to answer the threat of Mordor. Middle-Earth stands upon the brink of destruction. None can escape it. You will unite or you will fall. Each race is bound to this fate–this one doom."},
      {elrond, "Bring forth the Ring, Frodo."},
      {boromir, "So it is true…"},
      {boromir,
       "It is a gift. A gift to the foes of Mordor. Why not use this Ring? Long has my father, the Steward of Gondor, kept the forces of Mordor at bay. By the blood of our people are your lands kept safe! Give Gondor the weapon of the Enemy. Let us use it against him!"},
      {aragorn,
       "You cannot wield it! None of us can. The One Ring answers to Sauron alone. It has no other master."},
      {boromir, "And what would a ranger know of this matter?"}
    ]

    for {user, body} <- messages do
      case Chat.create_message(room, %{body: body}, user) do
        {:ok, _message} ->
          :ok

        {:error, changeset} ->
          IO.puts("Failed to create message:")
          IO.inspect(changeset.errors)
      end
    end

  {:error, changeset} ->
    IO.puts("Failed to create room:")
    IO.inspect(changeset.errors)
end

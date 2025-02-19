defmodule TrendsReplies.Repo do
  use Ecto.Repo,
    otp_app: :trends_replies,
    adapter: Ecto.Adapters.Postgres
end

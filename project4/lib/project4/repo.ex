defmodule Project4.Repo do
  use Ecto.Repo,
    otp_app: :project4,
    adapter: Ecto.Adapters.Postgres
end

defmodule CaravelaDemo.Repo do
  use Ecto.Repo,
    otp_app: :caravela_demo,
    adapter: Ecto.Adapters.Postgres
end

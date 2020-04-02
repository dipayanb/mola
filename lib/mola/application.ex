defmodule Mola.Application do
  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Application.ensure_all_started(:amqp)

    children = []

    opts = [strategy: :one_for_one, name: Mola.Application]
    Supervisor.start_link(children, opts)
  end
end

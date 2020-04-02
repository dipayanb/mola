defmodule Mola.ChannelsManager do
  @moduledoc """
  `ChannelsManager` is a supervisor for all the producers and consumers configured
  for one Connection
  """
  use Supervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts \\ []) do
    module = opts[:connection_module]

    with {:ok, _connection} <- amqp_connection(opts[:connection_module]),
         {:ok, consumer_specs} <- module.consumers(),
         {:ok, producer_specs} <- module.producers() do
      Logger.info("Creating the consumers and the producers defined.")
      children = consumer_specs ++ producer_specs
      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  defp amqp_connection(nil), do: {:error, "Connection module not provided"}

  defp amqp_connection(module) do
    module.amqp_connection()
  end
end

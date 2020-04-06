defmodule Mola.Producer do
  @moduledoc """
  A behavior which has to be implemented by a Consumer.

  ## Example

  ```
  defmodule MyApp.DummyConsumer do
    use Mola.Consumer

    @impl true
    @spec config :: Mola.Consumer.Config.t()
    def config,
      do: %Mola.Consumer.Config{
        exchange: %Mola.Exchange.Config{
          name: "text-exchange"
        },
        routing_key: "test.new"
      }
  end
  ```
  """

  require Logger

  @doc """
  Callback for retriving the configuration for the producer
  """
  @callback config() :: Mola.Producer.Config.t()

  defmacro __using__(_opts \\ []) do
    quote do
      use GenServer
      require Logger
      @behaviour unquote(__MODULE__)

      def start_link(options \\ []) do
        GenServer.start_link(__MODULE__, options, name: __MODULE__)
      end

      @impl true
      def init(options) do
        config = config()
        send(self(), {:bind, options})
        {:ok, %{channel: nil, producer_config: config, module: __MODULE__}}
      end

      # Publishes a message to an exchange.

      # This method publishes a message to the exchange defined in the return value of `config/0`
      # with the routing key defined in the same.

      # For the options refer this [link](https://hexdocs.pm/amqp/AMQP.Basic.html#publish/5-options)
      defp publish(message, options \\ []) do
        GenServer.call(__MODULE__, {:publish, message, options})
      end

      defdelegate handle_info(tuple, state), to: Mola.Producer
      defdelegate handle_call(tuple, from, state), to: Mola.Producer

      defoverridable unquote(__MODULE__)
    end
  end

  def handle_info({:bind, options}, %{producer_config: config} = state) do
    conn_module = options[:connection_module]
    {:ok, conn} = conn_module.amqp_connection

    case setup(conn, config) do
      {:ok, channel} ->
        {:noreply, %{state | channel: channel}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_call(
        {:publish, message, options},
        _from,
        %{channel: channel, producer_config: config, module: _module} = state
      ) do
    # config = module.config()
    options = Keyword.merge(options, config.options)
    exchange = Keyword.get(options, :exchange, exchange_name(config.exchange))
    routing_key = Keyword.get(options, :routing_key, config.routing_key)
    options = Keyword.drop(options, [:exchange, :routing_key])
    reply = AMQP.Basic.publish(channel, exchange, routing_key, message, options)
    {:reply, reply, state}
  end

  defp setup(conn, config) do
    with {:ok, channel} <- AMQP.Channel.open(conn),
         :ok <- may_be_declare_exchange(channel, config.exchange) do
      Logger.info("Producer channel created and exchange declared")
      {:ok, channel}
    end
  end

  defp may_be_declare_exchange(_channel, exchange) when is_binary(exchange) do
    :ok
  end

  defp may_be_declare_exchange(channel, %Mola.Exchange.Config{} = exchange) do
    options = [
      durable: exchange.durable,
      passive: exchange.passive,
      arguments: exchange.exchange_arguments
    ]

    AMQP.Exchange.declare(channel, exchange.name, exchange.type, options)
    :ok
  end

  defp exchange_name(exchange) when is_binary(exchange), do: exchange
  defp exchange_name(%Mola.Exchange.Config{} = exchange), do: exchange.name
end

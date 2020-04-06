defmodule Mola.Consumer do
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
  Callback for retriving the configuration for the consumer
  """
  @callback config() :: Mola.Consumer.Config.t()

  @type reason :: term

  @type on_deliver :: :ok | {:reject, reason}
  @type on_callback :: :ok | {:error, message :: String.t()}

  @callback deliver(AMQP.Channel.t(), Mola.Message.t()) :: on_deliver

  @callback cancel(AMQP.Channel.t()) :: on_callback
  @callback cancel_ok(AMQP.Channel.t()) :: on_callback
  @callback consume_ok(AMQP.Channel.t()) :: on_callback

  defmacro __using__(_opts \\ []) do
    quote location: :keep do
      use GenServer
      @behaviour Mola.Consumer

      def deliver(_channel, _message), do: :ok
      def cancel(_channel), do: :ok
      def cancel_ok(_channel), do: :ok
      def consume_ok(_channel), do: :ok

      def start_link(options \\ []) do
        GenServer.start_link(__MODULE__, options)
      end

      def init(options) do
        config = config()
        send(self(), {:bind, options})
        {:ok, %{channel: nil, consumer_tag: nil, consumer_config: config, module: __MODULE__}}
      end

      defdelegate handle_info(tuple, state), to: Mola.Consumer

      defoverridable unquote(__MODULE__)
    end
  end

  def handle_info({:bind, options}, %{consumer_config: config} = state) do
    conn_module = options[:connection_module]
    {:ok, conn} = conn_module.amqp_connection

    case setup(conn, config) do
      {:ok, channel, consumer_tag} ->
        {:noreply, %{state | consumer_tag: consumer_tag, channel: channel}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(
        {:basic_consume_ok, _meta},
        %{channel: channel, module: module} = state
      ) do
    case module.consume_ok(channel) do
      :ok -> Logger.debug("AMQP broker registered consumer for #{inspect(channel)}")
      error -> Logger.error("Handling error for broker register message #{inspect(error)}")
    end

    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, meta}, %{channel: channel, module: module} = state) do
    message = %Mola.Message{meta: meta, payload: payload}

    case module.deliver(channel, message) do
      :ok ->
        Logger.debug("Successfully consumed message #{inspect(message)}")
        AMQP.Basic.ack(channel, meta.delivery_tag)

      error ->
        Logger.error("Failed to consume message #{inspect(message)}, #{inspect(error)}")
    end

    {:noreply, state}
  end

  def handle_info(
        {:basic_cancel, %{consumer_tag: consumer_tag, no_wait: _no_wait} = _meta},
        %{channel: channel, module: module} = state
      ) do
    case module.cancel(channel) do
      :ok ->
        Logger.debug("AMQP broker confirmed cancelling consumer for #{inspect(channel)}")

      error ->
        Logger.error(
          "Handling error for broker cancel message for '#{consumer_tag}': #{inspect(error)}"
        )
    end

    {:stop, :normal, state}
  end

  def handle_info(
        {:basic_cancel_ok, %{consumer_tag: consumer_tag} = _meta},
        %{channel: channel, module: module} = state
      ) do
    case module.cancel_ok(channel) do
      :ok -> "AMQP broker confirmed cancelling consumer for #{inspect(channel)}"
      error -> "Error handling broker cancel for '#{consumer_tag}': #{inspect(error)}"
    end

    {:noreply, state}
  end

  defp setup(conn, config) do
    with {:ok, channel} <- AMQP.Channel.open(conn),
         :ok <- may_be_declare_exchange(channel, config.exchange),
         :ok <- declare_queue(channel, config),
         :ok <- bind_queue(channel, config),
         {:ok, consumer_tag} <- setup_consumer(channel, config) do
      Logger.info("Consumer channel created and queue declared")
      {:ok, channel, consumer_tag}
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

  defp declare_queue(channel, %Mola.Consumer.Config{} = config) do
    options = [
      auto_delete: config.auto_delete,
      exclusive: config.exclusive,
      arguments: config.queue_arguments
    ]

    {:ok, _info} = AMQP.Queue.declare(channel, config.name, options)
    :ok
  end

  defp bind_queue(channel, %Mola.Consumer.Config{} = config) do
    exchange_name = exchange_name(config.exchange)
    AMQP.Queue.bind(channel, config.name, exchange_name, routing_key: config.routing_key)
  end

  defp setup_consumer(channel, %Mola.Consumer.Config{} = config) do
    AMQP.Basic.qos(channel, prefetch_count: config.prefetch_count)
    AMQP.Basic.consume(channel, config.name, nil, no_ack: not config.consumer_ack)
  end

  defp exchange_name(exchange) when is_binary(exchange), do: exchange
  defp exchange_name(%Mola.Exchange.Config{} = exchange), do: exchange.name
end

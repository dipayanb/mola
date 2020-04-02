defmodule Mola.Connection do
  defmacro __using__(_opts \\ []) do
    quote do
      Module.register_attribute(__MODULE__, :consumers, accumulate: true)
      Module.register_attribute(__MODULE__, :producers, accumulate: true)
      use GenServer

      require Logger

      @backoff 1_000
      @connection_default [host: "localhost", port: 5672, connection_timeout: @backoff]

      def amqp_connection do
        GenServer.call(__MODULE__, :connection)
      end

      def init(configuration) do
        send(self(), :connect)
        {:ok, %{configuration: configuration, conn: nil}}
      end

      def start_link(connection_config \\ []) do
        GenServer.start_link(__MODULE__, connection_config, name: __MODULE__)
      end

      def handle_info(:connect, state) do
        Logger.info("Trying to connect to Message Q.")

        with configuration <- Keyword.merge(@connection_default, state.configuration),
             {:ok, connection} <- AMQP.Connection.open(configuration) do
          Process.monitor(connection.pid)
          {:noreply, %{state | conn: connection}}
        else
          {:error, reason} ->
            Logger.error("Failed to connect to Message Q. Reason #{inspect(reason)}")
            send(self(), :backoff)
            {:noreply, state}
        end
      end

      def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
        Logger.warn("Connection down, restarting...")
        {:stop, :normal, state}
      end

      def handle_info(:backoff, state) do
        Logger.info("Retrying connection in #{@backoff} milliseconds")
        Process.send_after(self(), :connect, @backoff)
        {:noreply, state}
      end

      def handle_call(:connection, _from, state) do
        case state[:conn] do
          nil -> {:reply, {:error, :not_connected}, state}
          conn -> {:reply, {:ok, conn}, state}
        end
      end

      import unquote(__MODULE__), only: [consumer: 1, producer: 1, consumer: 2, producer: 2]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    consumers = Module.get_attribute(env.module, :consumers) |> Enum.map(&children/1)
    producers = Module.get_attribute(env.module, :producers) |> Enum.map(&children/1)

    quote do
      def producers, do: {:ok, unquote(Macro.escape(producers))}

      def consumers, do: {:ok, unquote(Macro.escape(consumers))}
    end
  end

  defp children({module, opts}) do
    Supervisor.child_spec({module, opts}, type: :worker)
  end

  defmacro consumer(module, opts \\ []) do
    quote do
      @consumers {unquote(module),
                  unquote(Keyword.merge([connection_module: __CALLER__.module], opts))}
    end
  end

  defmacro producer(module, opts \\ []) do
    quote do
      @producers {unquote(module),
                  unquote(Keyword.merge([connection_module: __CALLER__.module], opts))}
    end
  end
end

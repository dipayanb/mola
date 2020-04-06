defmodule Mola.DummyConsumer do
  use Mola.Consumer
  require Logger

  @impl true
  @spec config :: Mola.Consumer.Config.t()
  def config,
    do: %Mola.Consumer.Config{
      name: "dummy_q",
      exchange: %Mola.Exchange.Config{
        name: "dummy"
      },
      routing_key: "dummy.txt"
    }

  @impl true
  def deliver(_channel, message) do
    Logger.info("Payload delivered.")
    IO.inspect(message.payload, label: "Payload >>>> ")
    IO.inspect(message.meta, label: "Meta >>>> ")
    :ok
  end
end

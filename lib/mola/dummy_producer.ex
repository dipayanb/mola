defmodule Mola.DummyProducer do
  use Mola.Producer

  @impl true
  def config,
    do: %Mola.Producer.Config{
      exchange: "dummy",
      routing_key: "dummy.txt"
    }

  def publish_my_message() do
    publish("Hello World")
  end
end

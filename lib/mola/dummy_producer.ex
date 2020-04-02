defmodule Mola.DummyProducer do
  use Mola.Producer

  @impl true
  def config,
    do: %Mola.Producer.Config{
      exchange: "dummy",
      routing_key: "dummy.txt"
    }
end

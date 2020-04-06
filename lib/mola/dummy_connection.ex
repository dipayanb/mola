defmodule Mola.DummyConnection do
  use Mola.Connection

  consumer(Mola.DummyConsumer)
  consumer(Mola.DummyConsumer)

  producer(Mola.DummyProducer)
end

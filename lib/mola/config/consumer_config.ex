defmodule Mola.Consumer.Config do
  @moduledoc """
  Consumer configuration

  This will be used in sending receive message by a consumer. `exchange` key can be a
  `String.t/0` or a `Mola.Exchange.Config`. If it is a `String.t/0` then
  the exchange declaration will not happen else, exchange will be created.

  For Queue arguments refer to [AMQP Documentation](https://hexdocs.pm/amqp/readme.html#types-of-arguments-and-headers).
  """

  @typedoc """
  A Consumer configuration
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          exchange: String.t() | Mola.Exchange.Config.t(),
          routing_key: String.t(),
          auto_delete: boolean(),
          exclusive: boolean(),
          prefetch_count: integer(),
          consumer_ack: boolean(),
          queue_arguments: AMQP.arguments()
        }
  @enforce_keys [:exchange, :routing_key]
  defstruct name: "",
            exchange: nil,
            routing_key: nil,
            auto_delete: false,
            exclusive: false,
            prefetch_count: 10,
            consumer_ack: true,
            queue_arguments: []
end

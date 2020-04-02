defmodule Mola.Producer.Config do
  @moduledoc """
  Producer configuration

  This will be used in sending message by a producer. `exchange` key can be a
  `String.t/0` or a `Mola.Exchange.Config`. If it is a `String.t/0` then
  the exchange declaration will not happen else, exchange will be created.

  `options` are passed on to AMQP library while publishing the message. This can
  be also overriden per message using the `Mola.Producer.publish/2` call.

  Refer to this [link](https://hexdocs.pm/amqp/AMQP.Basic.html#publish/5-options) for all the options.

  """

  @typedoc """
  A Producer configuration type
  """
  @type t() :: %__MODULE__{
          exchange: String.t() | Mola.Exchange.Config.t(),
          routing_key: String.t(),
          options: Keyword.t()
        }
  defstruct exchange: nil,
            routing_key: nil,
            options: []
end

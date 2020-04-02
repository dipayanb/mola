defmodule Mola.Exchange.Config do
  @moduledoc """
  A Configuration for Exchange.

  For Queue arguments refer to [AMQP Documentation](https://hexdocs.pm/amqp/readme.html#types-of-arguments-and-headers).
  """

  @typedoc """
  A Exchange configuration
  """
  @type t() :: %__MODULE__{
          type: :direct | :fanout | :topic | :headers,
          name: String.t(),
          durable: boolean(),
          passive: boolean(),
          exchange_arguments: AMQP.arguments()
        }
  @enforce_keys [:name]
  defstruct type: :direct,
            name: nil,
            durable: false,
            passive: false,
            exchange_arguments: []
end

defmodule Mola.Message do
  @moduledoc """
  Mola message struct
  """

  @typedoc """
  Message metadata
  """
  @type meta :: map

  @typedoc """
  Message payload
  """
  @type payload :: term

  @typedoc """
  Mola Message container
  """
  @type t :: %__MODULE__{meta: meta, payload: payload}
  defstruct meta: %{}, payload: <<>>
end

defmodule Mola.ConnectionManager do
  @moduledoc """
  `ConnectionManager` is a supervisor for one AMQP connection. This will
  supervise one active connection and the channels created from the connection.
  """
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init({module, opts}) do
    with otp_app <- Keyword.get(opts, :otp_app),
         {:ok, config} <- fetch_config(otp_app, module),
         {:ok, connection_config} <- connection_config(config) do
      children = [
        {module, connection_config},
        {Mola.ChannelsManager,
         %{
           connection_module: module
         }}
      ]

      Supervisor.init(children, strategy: :one_for_all)
    end
  end

  defp fetch_config(nil, module),
    do: {:error, ":opt_app is not provided for module #{module}"}

  defp fetch_config(otp_app, module) do
    case Application.fetch_env(otp_app, module) do
      {:ok, config} -> {:ok, config}
      :error -> {:error, "configuration not found for module #{module}"}
    end
  end

  defp connection_config(config) do
    config = config |> Keyword.drop([:consumers, :producers])
    {:ok, config}
  end
end

defmodule Mola.MixProject do
  use Mix.Project

  def project do
    [
      app: :mola,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:lager, :logger],
      mod: {Mola.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 1.4.0", runtime: false},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:earmark, "~> 1.4.3", only: :dev, runtime: false}
    ]
  end
end

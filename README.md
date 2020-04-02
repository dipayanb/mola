# Mola

**Work In Progress**

**An opinionated Elixir RabbitMQ Client**

This project is highly inspired from another Elixir RabbitMQ Client called
[Lapin](https://hexdocs.pm/lapin).

## Installation

**TODO**

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mola` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mola, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mola](https://hexdocs.pm/mola).

## Concepts

- **Connection**
- **Consumer**
- **Producer**

## Usage

**TODO**

Basic configuration

```elixir
config :otp_app, ConnectionModule,
  url: "",
  host: "",
  port: "",
  consumers: [
    ConsumerModule1: [
      exchange: "",
      queue: "",
      binding_key: ""
    ]
  ],
  producers: [
    ProducerModule1: [
      exchange: ""
    ]
  ]
```

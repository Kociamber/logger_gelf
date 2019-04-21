# LoggerGelf [![Build Status](https://travis-ci.org/kociamber/logger_gelf.svg?branch=master)](https://travis-ci.org/kociamber/logger_gelf)
**!!Currently WIP!!: Greylog backend for Elixir Logger.**

This application is able to generate Graylog Extended Log Format (GELF) UDP messages (TCP version coming soon)

## Installation

The package can be installed
by adding `logger_gelf` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logger_gelf, "~> 0.1.0"}
  ]
end
```
## Configuration

In the config.exs, add gelf_logger as a backend / add it to backends list:

```elixir
config :logger,
  backends: [:console, {LoggerGelf, :logger_gelf}]
```

You will also have to handle mandatory configuration:

```elixir
config :logger, :logger_gelf,
  application: "my_application",
  greylog_hostname: "127.0.0.1",
  greylog_hostport: 12201,
```
optional config options:

```elixir
hostname: "hostname", #defaults to :inet.gethostname/0 result
metadata: [:id, :module, :record], # defaults to :all
metadata_formatter: {Module, :function, arity}, # skipping the option will leave metadata as it is
json_encoder: Jason, #defaults to Jason, can be overriden by any module using  encode!/1 (ie. Poison)
compression: :gzip, # defaults to :gzip, :zlib or :raw are also available
```

## Usage

Just add to deps, configure and use Logger as usual.

## Credits

Credit where credit is due! This implementation was heavily inspired by:
[jschniper/gelf_logger](https://github.com/jschniper/gelf_logger).

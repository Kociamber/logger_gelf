defmodule LoggerGelf do
  @moduledoc """
  Greylog backend for Elixir Logger.
    # LoggerGelf [![Build Status](https://travis-ci.org/kociamber/logger_gelf.svg?branch=master)](https://travis-ci.org/kociamber/logger_gelf)

    This application is able to generate Graylog Extended Log Format (GELF) UDP messages (TCP version coming soon)

    ## Installation

    ## Configuration

    In the config.exs, add gelf_logger as a backend / add it to backends list:

    ```
    config :logger,
      backends: [:console, {LoggerGelf, :logger_gelf}]
    ```

    You will also have to handle mandatory configuration:

    ```
    config :logger, :logger_gelf,
      application: "my_application",
      greylog_hostname: "127.0.0.1",
      greylog_hostport: 12201,
    ```
    optional config options:

    ```
    hostname: "hostname", #defaults to :inet.gethostname/0 result
    metadata: [:id, :module, :record], # defaults to :all
    metadata_formatter: {Module, :function, arity}, # skipping the option will leave metadata as it is
    json_encoder: Jason, #defaults to Jason, can be overriden by any module using  encode!/1 (ie. Poison)
    compression: :gzip, # defaults to :gzip, :zlib or :raw are also available
    ```

    ## Usage

    Just add to deps, configure and use Logger as usual.

    In addition to the backend configuration, you might want to check the
    [Logger configuration](https://hexdocs.pm/logger/Logger.html) for other
    options that might be important for your particular environment. In
    particular, modifying the `:utc_log` setting might be necessary
    depending on your server configuration.
    This backend supports `metadata: :all`.

    ## Notes

    Credit where credit is due, this would not exist without
    [protofy/erl_graylog_sender](https://github.com/protofy/erl_graylog_sender).
  """

  # initialize and configure
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  # configure
  def handle_call({:configure, options}, state) do
    {:ok, configure(state[:name], options)}
  end

  # flush state
  def handle_event(:flush, state) do
    {:ok, state}
  end

  defp configure(name, options) do
    config = set_config(name, options)
    # below piping will result with building config map
    config
    # set up mandatory fields
    |> set_application()
    |> set_greylog_hostname()
    |> set_greylog_hostport
    # optional fields
    |> set_hostname()
    |> set_metadata()
    |> set_metadata_formatter()
    |> set_json_encoder()
    |> set_compression()
  end

  # fetch config from dependant application and merge with options
  defp set_config(name, options) do
    :logger
    |> Application.get_env(name, [])
    |> Keyword.merge(options)
  end

  # fetch application name
  defp set_application(config) do
    application = Keyword.get(config, :application)
    {%{application: application}, config}
  end

  # fetch greylog hostname
  defp set_greylog_hostname({map, config}) do
    case Keyword.get(config, :greylog_hostname, nil) do
      nil ->
        {map, config}

      greylog_hostname ->
        map = Map.merge(map, :greylog_hostname, greylog_hostname)
        {map, config}
    end
  end

  # fetch greylog hostport
  defp set_greylog_hostport({map, config}) do
    case Keyword.get(config, :greylog_hostport, nil) do
      nil ->
        {map, config}

      greylog_hostport ->
        map = Map.merge(map, :greylog_hostport, greylog_hostport)
        {map, config}
    end
  end

  # set hostname, defaults to config provided value
  defp set_hostname({map, config}) do
    {:ok, hostname} = :inet.gethostname()
    hostname = Keyword.get(config, :hostname, hostname)
    map = Map.merge(map, :hostname, hostname)
    {map, config}
  end

  # set metadata, defaults to :all
  defp set_metadata({map, config}) do
    metadata = Keyword.get(config, :metadata, :all)
    map = Map.merge(map, :metadata, metadata)
    {map, config}
  end

  # set formatter for metadata
  defp set_metadata_formatter({map, config}) do
    with true <- Keyword.has_key?(config, :custom_md_format),
         {module, function, arity} = Keyword.get(config, :custom_md_format),
         true <- Code.ensure_compiled?(module),
         true <- function_exported?(module, function, arity) do
      map = Map.merge(map, :metadata, {module, function, arity})
      {map, config}
    else
      _ -> {map, config}
    end
  end

  # set json encoder, defaults to Json
  defp set_json_encoder({map, config}) do
    json_encoder = Keyword.get(config, :json_encoder, Jason)
    map = Map.merge(map, :json_encoder, json_encoder)
    {map, config}
  end

  # set compression, defaults ti :gzip
  defp set_compression({map, config}) do
    compression = Keyword.get(config, :compression, :gzip)
    map = Map.merge(map, :compression, compression)
    {map, config}
  end
end

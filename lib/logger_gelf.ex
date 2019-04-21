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
    level: :warn, # defaults to lowest level (:debug)
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
  """
  @behaviour :gen_event
  # initialize and configure
  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  # configure
  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(state[:name], options)}
  end

  # all events are being passed to backend in below format:
  # {level, group_leader, {Logger, message, timestamp, metadata}} | :flush

  # ignore messages where the group leader is in a different node
  def handle_event({_log_level, group_leader, {Logger, _, _, _}}, state)
      when node(group_leader) != node() do
    {:ok, state}
  end
  # ignore messages where logging level is lower than set up
  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, msg, ts, md, state)
    end

    {:ok, state}
  end

  # flush state
  def handle_event(:flush, state) do
    {:ok, state}
  end

  defp configure(name, options) do
    config = set_config(name, options)
    # below piping will result in building config map
    config
    # set up mandatory fields
    |> set_application()
    |> set_greylog_hostname()
    |> set_greylog_hostport
    # optional fields
    |> set_hostname()
    |> set_level()
    # |> set_format()
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
        {%{map | greylog_hostname: greylog_hostname}, config}
    end
  end

  # fetch greylog hostport
  defp set_greylog_hostport({map, config}) do
    case Keyword.get(config, :greylog_hostport, nil) do
      nil ->
        {map, config}

      greylog_hostport ->
        {%{map | greylog_hostport: greylog_hostport}, config}
    end
  end

  # set hostname, defaults to config provided value
  defp set_hostname({map, config}) do
    {:ok, hostname} = :inet.gethostname()
    hostname = Keyword.get(config, :hostname, hostname)
    {%{map | hostname: hostname}, config}
  end
  # set backend's logging level, defaults to debug
  defp set_level({map, config}) do
    level = Keyword.get(config, :level, :debug)
    {%{map | level: level}, config}
  end

  # set metadata, defaults to :all
  defp set_metadata({map, config}) do
    metadata = Keyword.get(config, :metadata, :all)
    {%{map | metadata: metadata}, config}
  end

  # set formatter for metadata
  defp set_metadata_formatter({map, config}) do
    with true <- Keyword.has_key?(config, :metadata_formatter),
         {module, function, arity} = Keyword.get(config, :metadata_formatter),
         true <- Code.ensure_compiled?(module),
         true <- function_exported?(module, function, arity) do
      {%{map | metadata_formatter: {module, function, arity}}, config}
    else
      _ -> {map, config}
    end
  end

  # set json encoder, defaults to Json
  # TODO: add with statement as above to check whether json encoder exists
  defp set_json_encoder({map, config}) do
    json_encoder = Keyword.get(config, :json_encoder, Jason)
    {%{map | json_encoder: json_encoder}, config}
  end

  # set compression, defaults ti :gzip
  defp set_compression({map, config}) do
    compression = Keyword.get(config, :compression, :gzip)
    {%{map | compression: compression}, config}
  end

  defp log_event(level, message, timestamp, metadata, state) do
    # send stuff to Greylog
  end
end

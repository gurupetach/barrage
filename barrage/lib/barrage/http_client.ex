defmodule Barrage.HttpClient do
  @moduledoc """
  HTTP client for making requests during directory brute-forcing.
  """

  @type response :: %{
          status_code: integer(),
          headers: list(),
          body: binary(),
          url: String.t(),
          content_length: integer()
        }

  @spec get(String.t(), map()) :: {:ok, response()} | {:error, term()}
  def get(url, config) do
    headers = build_headers(config)
    options = build_options(config)

    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{} = response} ->
        {:ok, format_response(response, url)}

      {:error, %HTTPoison.Error{reason: :timeout}} ->
        # Handle timeout specifically to avoid hanging the scanner
        {:error, :timeout}

      {:error, %HTTPoison.Error{reason: :recv_timeout}} ->
        # Handle receive timeout specifically
        {:error, :recv_timeout}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def build_headers(config) do
    [
      {"User-Agent", config.user_agent}
    ]
  end

  def build_options(config) do
    # Convert timeout from seconds to milliseconds and use shorter receive timeout
    timeout_ms = config.timeout * 1000
    # Max 3 seconds for receive
    recv_timeout = min(timeout_ms, 3000)

    [
      timeout: timeout_ms,
      recv_timeout: recv_timeout,
      follow_redirect: false,
      ssl: [verify: :verify_none],
      # Add connection timeout to prevent hanging on connection issues
      # 2 seconds max for connection
      connect_timeout: 2000,
      # Limit response body size to prevent memory issues with large responses
      # 1MB limit
      max_body_length: 1_048_576
    ]
  end

  def format_response(%HTTPoison.Response{} = response, url) do
    content_length = get_content_length(response.headers)

    %{
      status_code: response.status_code,
      headers: response.headers,
      body: response.body,
      url: url,
      content_length: content_length
    }
  end

  def get_content_length(headers) do
    headers
    |> Enum.find(fn {key, _value} ->
      String.downcase(key) == "content-length"
    end)
    |> case do
      {_key, value} ->
        case Integer.parse(value) do
          {length, _} -> length
          :error -> byte_size("")
        end

      nil ->
        0
    end
  end
end

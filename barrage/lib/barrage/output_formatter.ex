defmodule Barrage.OutputFormatter do
  @moduledoc """
  Formats and displays scan results.
  """

  @spec format_result(map(), map()) :: :ok
  def format_result(result, config) do
    unless config.quiet do
      case result do
        %{status_code: code, url: url, content_length: length} ->
          status_color = get_status_color(code)
          size_str = format_size(length)

          IO.puts("#{status_color}#{code}\e[0m      #{size_str}    #{url}")

        %{status: :error, url: url, reason: reason} ->
          if config.verbose do
            IO.puts("\e[31mERROR\e[0m     -         #{url} (#{reason})")
          end

        _ ->
          :ok
      end
    end

    :ok
  end

  @spec print_summary(list(map()), map()) :: :ok
  def print_summary(results, config) do
    unless config.quiet do
      valid_results = Enum.reject(results, &is_nil/1)

      IO.puts("")
      IO.puts("===============================================================")
      IO.puts("SCAN COMPLETE")
      IO.puts("===============================================================")
      IO.puts("Total requests: #{length(valid_results)}")

      # Group by status code
      by_status = Enum.group_by(valid_results, & &1.status_code)

      Enum.each(by_status, fn {status, items} ->
        IO.puts("Status #{status}: #{length(items)} responses")
      end)

      IO.puts("===============================================================")
    end

    :ok
  end

  defp get_status_color(code) do
    case code do
      # Green
      200 -> "\e[32m"
      # Green
      201 -> "\e[32m"
      # Green
      204 -> "\e[32m"
      # Yellow
      301 -> "\e[33m"
      # Yellow
      302 -> "\e[33m"
      # Yellow
      307 -> "\e[33m"
      # Magenta
      401 -> "\e[35m"
      # Magenta
      403 -> "\e[35m"
      # Red
      500 -> "\e[31m"
      # White
      _ -> "\e[37m"
    end
  end

  defp format_size(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1024 * 1024 ->
        "#{Float.round(bytes / (1024 * 1024), 2)}MB"

      bytes >= 1024 ->
        "#{Float.round(bytes / 1024, 2)}KB"

      true ->
        "#{bytes}B"
    end
    |> String.pad_leading(8)
  end

  defp format_size(_), do: "     -  "
end

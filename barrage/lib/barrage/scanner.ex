defmodule Barrage.Scanner do
  @moduledoc """
  Main scanner module that orchestrates the brute-forcing process.
  """

  alias Barrage.{Wordlist, HttpClient, ResponseAnalyzer, OutputFormatter, TechnologyDetector}

  def run(config) do
    with {:ok, words} <- load_words_with_detection(config),
         :ok <- validate_target(config.url) do
      paths = Wordlist.generate_paths(config.url, words, config.extensions)
      total_requests = length(paths)

      print_scan_info(config, total_requests)

      scan_results =
        paths
        |> Task.async_stream(
          &scan_path(&1, config),
          max_concurrency: config.threads,
          timeout: config.timeout + 5000,
          on_timeout: :kill_task
        )
        |> Stream.map(&handle_task_result/1)
        |> Stream.reject(&is_nil/1)
        |> Enum.to_list()

      OutputFormatter.print_summary(scan_results, config)

      :ok
    else
      {:error, {:file_error, :enoent}} ->
        IO.puts(:stderr, "Error: Wordlist file '#{config.wordlist}' not found.")
        IO.puts(:stderr, "Please provide a valid wordlist file with -w option.")
        System.halt(1)

      {:error, reason} ->
        IO.puts(:stderr, "Error: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp validate_target(url) do
    case HttpClient.get(url, %{user_agent: "Barrage/0.1.0", timeout: 10000}) do
      {:ok, _response} ->
        :ok

      # Allow timeout on initial check
      {:error, :timeout} ->
        :ok

      {:error, reason} ->
        {:error, "Failed to connect to target: #{inspect(reason)}"}
    end
  end

  defp print_scan_info(config, total_requests) do
    unless config.quiet do
      IO.puts("Target:     #{config.url}")
      IO.puts("Wordlists:  #{config.wordlist} + all technology wordlists")
      IO.puts("Threads:    #{config.threads}")
      IO.puts("Extensions: #{Enum.join(config.extensions, ", ")}")
      IO.puts("Requests:   #{total_requests}")
      IO.puts("Status codes: #{config.status_codes |> MapSet.to_list() |> Enum.join(", ")}")
      IO.puts("")
      IO.puts("Starting comprehensive scan...")
      IO.puts("")
    end
  end

  defp scan_path(url, config) do
    result =
      case HttpClient.get(url, config) do
        {:ok, response} ->
          ResponseAnalyzer.analyze(response, config)

        {:error, reason} ->
          if config.verbose do
            %{url: url, status: :error, reason: reason}
          else
            nil
          end
      end

    if result && should_display?(result, config) do
      OutputFormatter.format_result(result, config)
    end

    result
  end

  defp handle_task_result({:ok, result}), do: result
  defp handle_task_result({:exit, _reason}), do: nil

  defp should_display?(result, config) do
    case result do
      %{status_code: code} -> MapSet.member?(config.status_codes, code)
      %{status: :error} -> config.verbose
      _ -> false
    end
  end

  defp load_words_with_detection(config) do
    # First load the basic wordlist
    with {:ok, base_words} <- Wordlist.load(config.wordlist) do
      # Perform initial reconnaissance to detect technology (for display purposes)
      case perform_initial_detection(config.url) do
        {:ok, {technologies, server_info}} ->
          unless config.quiet do
            detected_tech =
              technologies
              |> Enum.map(&TechnologyDetector.technology_to_string/1)
              |> Enum.join(", ")

            IO.puts("Detected technologies: #{detected_tech}")
            print_server_info(server_info)
          end

        {:error, _} ->
          unless config.quiet do
            IO.puts("Technology detection failed, using all wordlists")
          end
      end

      # Always load ALL technology-specific wordlists for comprehensive coverage
      all_technology_words = load_all_technology_wordlists()

      # Merge base words with all technology-specific words
      all_words = (base_words ++ all_technology_words) |> Enum.uniq()

      {:ok, all_words}
    end
  end

  defp perform_initial_detection(url) do
    case HttpClient.get(url, %{user_agent: "Barrage/0.1.0", timeout: 10000}) do
      {:ok, response} ->
        result = TechnologyDetector.detect_technology(response)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp print_server_info(server_info) do
    IO.puts("Server Information:")
    IO.puts("  IP Address: #{server_info.ip_address}")
    IO.puts("  Server: #{server_info.server}")
    IO.puts("  Powered By: #{server_info.powered_by}")
    IO.puts("  Hosting Provider: #{server_info.hosting_provider}")
    IO.puts("  OS Info: #{server_info.os_info}")
    IO.puts("  Cloud Platform: #{server_info.cloud_platform}")

    unless Enum.empty?(server_info.database_hints) do
      IO.puts("  Database Hints: #{Enum.join(server_info.database_hints, ", ")}")
    end

    security_headers = server_info.security_headers

    missing_security_headers =
      security_headers
      |> Enum.filter(fn {_key, value} -> not value end)
      |> Enum.map(fn {key, _} -> key end)

    unless Enum.empty?(missing_security_headers) do
      IO.puts("  Missing Security Headers: #{Enum.join(missing_security_headers, ", ")}")
    end

    IO.puts("")
  end

  defp load_all_technology_wordlists() do
    all_technologies = [
      :elixir_phoenix,
      :vue_nuxt,
      :react_next,
      :php_laravel,
      :wordpress,
      :django_python,
      :nodejs_express,
      :java_spring,
      :ruby_rails,
      :dotnet_core,
      :cms_drupal,
      :cms_joomla,
      :go_frameworks,
      :ecommerce_platforms
    ]

    all_technologies
    |> Enum.flat_map(fn tech ->
      wordlist_path = TechnologyDetector.get_wordlist_for_technology(tech)

      case Wordlist.load(wordlist_path) do
        {:ok, words} -> words
        {:error, _} -> []
      end
    end)
    |> Enum.uniq()
  end
end

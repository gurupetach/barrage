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
      IO.puts("Wordlist:   #{config.wordlist}")
      IO.puts("Threads:    #{config.threads}")
      IO.puts("Extensions: #{Enum.join(config.extensions, ", ")}")
      IO.puts("Requests:   #{total_requests}")
      IO.puts("Status codes: #{config.status_codes |> MapSet.to_list() |> Enum.join(", ")}")
      IO.puts("")
      IO.puts("Starting scan...")
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
      # Perform initial reconnaissance to detect technology
      case perform_initial_detection(config.url) do
        {:ok, technologies} ->
          unless config.quiet do
            detected_tech =
              technologies
              |> Enum.map(&TechnologyDetector.technology_to_string/1)
              |> Enum.join(", ")

            IO.puts("Detected technologies: #{detected_tech}")
          end

          # Load additional words based on detected technologies
          additional_words = load_technology_specific_words(technologies)

          # Merge base words with technology-specific words
          all_words = (base_words ++ additional_words) |> Enum.uniq()

          {:ok, all_words}

        {:error, _} ->
          # Fall back to base wordlist if detection fails
          {:ok, base_words}
      end
    end
  end

  defp perform_initial_detection(url) do
    case HttpClient.get(url, %{user_agent: "Barrage/0.1.0", timeout: 10000}) do
      {:ok, response} ->
        technologies = TechnologyDetector.detect_technology(response)
        {:ok, technologies}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_technology_specific_words(technologies) do
    technologies
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

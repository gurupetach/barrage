defmodule Barrage.OutputFormatter do
  @moduledoc """
  Formats and displays scan results.
  """

  @spec format_result(map(), map()) :: :ok
  def format_result(result, config) do
    unless config.quiet do
      case result do
        %{status_code: code, url: url, content_length: length} = full_result ->
          status_color = get_status_color(code)
          size_str = format_size(length)

          # Basic output
          base_output = "#{status_color}#{code}\e[0m      #{size_str}    #{url}"

          # Add intelligence if enabled
          enhanced_output =
            if config[:intelligent] do
              add_intelligence_info(base_output, full_result)
            else
              base_output
            end

          IO.puts(enhanced_output)

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
      by_status =
        Enum.group_by(valid_results, fn result ->
          Map.get(result, :status_code, :error)
        end)

      Enum.each(by_status, fn {status, items} ->
        IO.puts("Status #{status}: #{length(items)} responses")
      end)

      IO.puts("===============================================================")
      print_legal_footer()
    end

    :ok
  end

  defp print_legal_footer do
    IO.puts("")
    IO.puts("⚖️  LEGAL DISCLAIMER:")
    IO.puts("Results above are for authorized security testing only.")
    IO.puts("Unauthorized use of this information may violate laws.")
    IO.puts("Users are solely responsible for legal compliance.")
    IO.puts("")
    IO.puts("📄 License: See LICENSE file for usage restrictions")
    IO.puts("🔒 Report security issues responsibly")
    IO.puts("===============================================================")
  end

  def get_status_color(code) do
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

  def format_size(bytes) when is_integer(bytes) do
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

  def format_size(_), do: "     -  "

  defp add_intelligence_info(base_output, result) do
    info_parts = []

    # Add file type info
    info_parts =
      if Map.get(result, :file_type) != :unknown do
        [format_file_type(result.file_type) | info_parts]
      else
        info_parts
      end

    # Add technology info
    info_parts =
      if length(Map.get(result, :technologies, [])) > 0 do
        tech_str =
          result.technologies
          |> Enum.map(&format_technology/1)
          |> Enum.join(", ")

        ["\e[36m[#{tech_str}]\e[0m" | info_parts]
      else
        info_parts
      end

    # Add security findings
    info_parts =
      if length(Map.get(result, :security_findings, [])) > 0 do
        findings_str =
          result.security_findings
          # Remove duplicates
          |> Enum.uniq()
          # Limit to first 3 findings
          |> Enum.take(3)
          |> Enum.map(&format_security_finding/1)
          |> Enum.join(", ")

        ["\e[31m⚠ #{findings_str}\e[0m" | info_parts]
      else
        info_parts
      end

    case info_parts do
      [] -> base_output
      parts -> base_output <> "  " <> Enum.join(Enum.reverse(parts), " ")
    end
  end

  defp format_file_type(file_type) do
    type_str =
      case file_type do
        :php -> "PHP"
        :javascript -> "JS"
        :css -> "CSS"
        :json -> "JSON"
        :xml -> "XML"
        :html -> "HTML"
        :text -> "TXT"
        :pdf -> "PDF"
        :archive -> "ZIP"
        :database -> "DB"
        :log -> "LOG"
        :backup -> "BAK"
        :config -> "CFG"
        _ -> ""
      end

    if type_str != "" do
      "\e[33m[#{type_str}]\e[0m"
    else
      ""
    end
  end

  defp format_technology(tech) do
    case tech do
      :elixir_phoenix -> "Phoenix"
      :vue_nuxt -> "Vue"
      :react_next -> "React"
      :php_laravel -> "Laravel"
      :wordpress -> "WordPress"
      :django_python -> "Django"
      :nodejs_express -> "Node.js"
      _ -> Atom.to_string(tech)
    end
  end

  defp format_security_finding(finding) do
    case finding do
      :sql_error_disclosure -> "SQL Error"
      :php_error_disclosure -> "PHP Error"
      :python_error_disclosure -> "Python Error"
      :exception_disclosure -> "Exception"
      :debug_info_disclosure -> "Debug Info"
      :stacktrace_disclosure -> "Stacktrace"
      :localhost_reference -> "Localhost"
      :password_reference -> "Password"
      :secret_reference -> "Secret"
      :api_key_reference -> "API Key"
      :token_reference -> "Token"
      :git_exposure -> "Git Exposed"
      :svn_exposure -> "SVN Exposed"
      :env_file_exposure -> "ENV File"
      :backup_file_exposure -> "Backup File"
      :temp_file_exposure -> "Temp File"
      :config_file_exposure -> "Config File"
      :missing_security_headers -> "Missing Headers"
      :directory_listing -> "Dir Listing"
      _ -> Atom.to_string(finding)
    end
  end
end

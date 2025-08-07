defmodule Barrage.ResponseAnalyzer do
  @moduledoc """
  Analyzes HTTP responses and determines if they should be reported.
  """

  alias Barrage.TechnologyDetector

  @type analysis_result :: %{
          url: String.t(),
          status_code: integer(),
          content_length: integer(),
          response_time: integer(),
          interesting: boolean(),
          technologies: list(atom()),
          file_type: atom(),
          security_findings: list(atom())
        }

  @spec analyze(map(), map()) :: analysis_result()
  def analyze(response, config) do
    technologies =
      if config[:intelligent], do: TechnologyDetector.detect_technology(response), else: []

    file_type = detect_file_type(response)
    security_findings = detect_security_findings(response)

    %{
      url: response.url,
      status_code: response.status_code,
      content_length: response.content_length,
      # TODO: Add timing
      response_time: 0,
      interesting: is_interesting?(response),
      technologies: technologies,
      file_type: file_type,
      security_findings: security_findings
    }
  end

  defp is_interesting?(response) do
    case response.status_code do
      200 -> true
      204 -> true
      301 -> true
      302 -> true
      307 -> true
      401 -> true
      403 -> has_content?(response)
      404 -> false
      _ -> false
    end
  end

  defp has_content?(%{content_length: length}) when length > 0, do: true
  defp has_content?(%{body: body}) when byte_size(body) > 0, do: true
  defp has_content?(_), do: false

  @spec filter_false_positives(list(analysis_result()), map()) :: list(analysis_result())
  def filter_false_positives(results, _config) do
    # Group by status code and content length to identify patterns
    grouped = Enum.group_by(results, &{&1.status_code, &1.content_length})

    # Filter out results that appear too frequently (likely false positives)
    filtered_groups =
      Enum.reject(grouped, fn {_key, values} ->
        length(values) > 10 and all_same_pattern?(values)
      end)

    filtered_groups
    |> Enum.flat_map(fn {_key, values} -> values end)
    |> Enum.sort_by(& &1.url)
  end

  defp all_same_pattern?(results) do
    case results do
      [first | rest] ->
        Enum.all?(rest, fn result ->
          result.status_code == first.status_code and
            result.content_length == first.content_length
        end)

      [] ->
        false
    end
  end

  defp detect_file_type(response) do
    url_lower = String.downcase(response.url)

    headers =
      response.headers
      |> Enum.into(%{}, fn {k, v} -> {String.downcase(k), String.downcase(v)} end)

    cond do
      String.contains?(url_lower, ".php") ->
        :php

      String.contains?(url_lower, ".json") ->
        :json

      String.contains?(url_lower, ".js") ->
        :javascript

      String.contains?(url_lower, ".css") ->
        :css

      String.contains?(url_lower, ".xml") ->
        :xml

      String.contains?(url_lower, ".html") or String.contains?(url_lower, ".htm") ->
        :html

      String.contains?(url_lower, ".txt") ->
        :text

      String.contains?(url_lower, ".pdf") ->
        :pdf

      String.contains?(url_lower, ".zip") or String.contains?(url_lower, ".tar") ->
        :archive

      String.contains?(url_lower, ".sql") or String.contains?(url_lower, ".db") ->
        :database

      String.contains?(url_lower, ".log") ->
        :log

      String.contains?(url_lower, ".bak") or String.contains?(url_lower, ".backup") ->
        :backup

      String.contains?(url_lower, ".env") ->
        :config

      Map.get(headers, "content-type", "") |> String.contains?("application/json") ->
        :json

      Map.get(headers, "content-type", "") |> String.contains?("text/html") ->
        :html

      Map.get(headers, "content-type", "") |> String.contains?("text/css") ->
        :css

      Map.get(headers, "content-type", "") |> String.contains?("application/javascript") ->
        :javascript

      true ->
        :unknown
    end
  end

  defp detect_security_findings(response) do
    findings = []
    body_lower = if is_binary(response.body), do: String.downcase(response.body), else: ""

    headers =
      response.headers
      |> Enum.into(%{}, fn {k, v} -> {String.downcase(k), String.downcase(v)} end)

    url_lower = String.downcase(response.url)

    findings
    |> maybe_add_finding(String.contains?(body_lower, "sql error"), :sql_error_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "mysql error"), :sql_error_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "fatal error"), :php_error_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "warning:"), :php_error_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "traceback"), :python_error_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "exception"), :exception_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "debug"), :debug_info_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "stacktrace"), :stacktrace_disclosure)
    |> maybe_add_finding(String.contains?(body_lower, "localhost"), :localhost_reference)
    |> maybe_add_finding(String.contains?(body_lower, "127.0.0.1"), :localhost_reference)
    |> maybe_add_finding(String.contains?(body_lower, "password"), :password_reference)
    |> maybe_add_finding(String.contains?(body_lower, "secret"), :secret_reference)
    |> maybe_add_finding(String.contains?(body_lower, "api_key"), :api_key_reference)
    |> maybe_add_finding(String.contains?(body_lower, "token"), :token_reference)
    |> maybe_add_finding(String.contains?(url_lower, ".git"), :git_exposure)
    |> maybe_add_finding(String.contains?(url_lower, ".svn"), :svn_exposure)
    |> maybe_add_finding(String.contains?(url_lower, ".env"), :env_file_exposure)
    |> maybe_add_finding(String.contains?(url_lower, "backup"), :backup_file_exposure)
    |> maybe_add_finding(String.contains?(url_lower, ".bak"), :backup_file_exposure)
    |> maybe_add_finding(String.contains?(url_lower, ".old"), :backup_file_exposure)
    |> maybe_add_finding(String.contains?(url_lower, ".tmp"), :temp_file_exposure)
    |> maybe_add_finding(String.contains?(url_lower, "config"), :config_file_exposure)
    |> maybe_add_finding(not Map.has_key?(headers, "x-frame-options"), :missing_security_headers)
    |> maybe_add_finding(
      not Map.has_key?(headers, "x-content-type-options"),
      :missing_security_headers
    )
    |> maybe_add_finding(
      response.status_code == 403 and response.content_length > 0,
      :directory_listing
    )
    |> maybe_add_finding(
      response.status_code == 200 and String.contains?(body_lower, "index of"),
      :directory_listing
    )
  end

  defp maybe_add_finding(findings, true, finding), do: [finding | findings]
  defp maybe_add_finding(findings, false, _finding), do: findings
end

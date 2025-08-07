defmodule Barrage.ResponseAnalyzer do
  @moduledoc """
  Analyzes HTTP responses and determines if they should be reported.
  """

  @type analysis_result :: %{
          url: String.t(),
          status_code: integer(),
          content_length: integer(),
          response_time: integer(),
          interesting: boolean()
        }

  @spec analyze(map(), map()) :: analysis_result()
  def analyze(response, _config) do
    %{
      url: response.url,
      status_code: response.status_code,
      content_length: response.content_length,
      # TODO: Add timing
      response_time: 0,
      interesting: is_interesting?(response)
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
end

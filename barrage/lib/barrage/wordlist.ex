defmodule Barrage.Wordlist do
  @moduledoc """
  Wordlist loading and processing functionality.
  """

  @spec load(String.t()) :: {:ok, list(String.t())} | {:error, term()}
  def load(wordlist_path) do
    content =
      case File.read(wordlist_path) do
        {:ok, file_content} ->
          file_content

        {:error, _} ->
          # Try to load from embedded wordlists
          filename = Path.basename(wordlist_path)
          Barrage.EmbeddedWordlists.get_wordlist(filename)
      end

    words =
      content
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    {:ok, words}
  end

  @spec generate_paths(String.t(), list(String.t()), list(String.t())) :: list(String.t())
  def generate_paths(base_url, words, extensions) do
    base_url = normalize_url(base_url)

    paths =
      for word <- words,
          ext <- ["" | extensions],
          do: build_url(base_url, word <> ext)

    Enum.uniq(paths)
  end

  defp normalize_url(url) do
    url = String.trim_trailing(url, "/")

    if String.starts_with?(url, "http://") or String.starts_with?(url, "https://") do
      url
    else
      "http://" <> url
    end
  end

  defp build_url(base_url, path) do
    path = String.trim_leading(path, "/")
    base_url <> "/" <> path
  end

  @spec count_words(String.t()) :: {:ok, integer()} | {:error, term()}
  def count_words(wordlist_path) do
    try do
      content =
        case File.read(wordlist_path) do
          {:ok, file_content} ->
            file_content

          {:error, _} ->
            # Try to load from embedded wordlists
            filename = Path.basename(wordlist_path)
            Barrage.EmbeddedWordlists.get_wordlist(filename)
        end

      count =
        content
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.count()

      {:ok, count}
    rescue
      error -> {:error, error}
    end
  end
end

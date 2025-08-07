defmodule Barrage.TechnologyDetector do
  @moduledoc """
  Detects web technologies based on HTTP responses, headers, and content analysis.
  """

  @type technology ::
          :elixir_phoenix
          | :vue_nuxt
          | :react_next
          | :php_laravel
          | :wordpress
          | :django_python
          | :nodejs_express
          | :unknown

  @spec detect_technology(map()) :: list(technology())
  def detect_technology(response) do
    []
    |> detect_from_headers(response.headers)
    |> detect_from_content(response.body)
    |> detect_from_url(response.url)
    |> Enum.uniq()
    |> case do
      [] -> [:unknown]
      technologies -> technologies
    end
  end

  defp detect_from_headers(acc, headers) do
    headers_map =
      headers
      |> Enum.map(fn {key, value} -> {String.downcase(key), String.downcase(value)} end)
      |> Map.new()

    acc
    |> check_server_header(headers_map)
    |> check_framework_headers(headers_map)
    |> check_technology_headers(headers_map)
  end

  defp check_server_header(acc, headers) do
    case Map.get(headers, "server") do
      nil ->
        acc

      server ->
        cond do
          String.contains?(server, "phoenix") ->
            [:elixir_phoenix | acc]

          String.contains?(server, "cowboy") ->
            [:elixir_phoenix | acc]

          String.contains?(server, "nginx") and String.contains?(server, "php") ->
            [:php_laravel | acc]

          String.contains?(server, "apache") and String.contains?(server, "php") ->
            [:php_laravel | acc]

          String.contains?(server, "express") ->
            [:nodejs_express | acc]

          String.contains?(server, "node") ->
            [:nodejs_express | acc]

          String.contains?(server, "django") ->
            [:django_python | acc]

          String.contains?(server, "gunicorn") ->
            [:django_python | acc]

          String.contains?(server, "uvicorn") ->
            [:django_python | acc]

          true ->
            acc
        end
    end
  end

  defp check_framework_headers(acc, headers) do
    acc
    |> maybe_add_tech(Map.has_key?(headers, "x-powered-by"), fn ->
      case Map.get(headers, "x-powered-by") do
        powered_by when is_binary(powered_by) ->
          cond do
            String.contains?(powered_by, "php") -> [:php_laravel]
            String.contains?(powered_by, "express") -> [:nodejs_express]
            String.contains?(powered_by, "next") -> [:react_next]
            String.contains?(powered_by, "nuxt") -> [:vue_nuxt]
            true -> []
          end

        _ ->
          []
      end
    end)
    |> maybe_add_tech(Map.has_key?(headers, "x-generator"), fn ->
      case Map.get(headers, "x-generator") do
        generator when is_binary(generator) ->
          cond do
            String.contains?(generator, "wordpress") -> [:wordpress]
            String.contains?(generator, "django") -> [:django_python]
            String.contains?(generator, "next") -> [:react_next]
            String.contains?(generator, "nuxt") -> [:vue_nuxt]
            true -> []
          end

        _ ->
          []
      end
    end)
  end

  defp check_technology_headers(acc, headers) do
    acc
    |> maybe_add_tech(Map.has_key?(headers, "x-wp-version"), [:wordpress])
    |> maybe_add_tech(Map.has_key?(headers, "x-pingback"), [:wordpress])
    |> maybe_add_tech(Map.has_key?(headers, "x-nextjs-page"), [:react_next])
    |> maybe_add_tech(Map.has_key?(headers, "x-nuxt-no-ssr"), [:vue_nuxt])
    |> maybe_add_tech(Map.has_key?(headers, "x-phoenix-endpoint"), [:elixir_phoenix])
    |> maybe_add_tech(Map.has_key?(headers, "x-request-id"), [:elixir_phoenix])
  end

  defp detect_from_content(acc, body) when is_binary(body) do
    body_lower = String.downcase(body)

    acc
    |> maybe_add_tech(String.contains?(body_lower, "phoenix"), [:elixir_phoenix])
    |> maybe_add_tech(String.contains?(body_lower, "liveview"), [:elixir_phoenix])
    |> maybe_add_tech(String.contains?(body_lower, "phx-"), [:elixir_phoenix])
    |> maybe_add_tech(String.contains?(body_lower, "__next"), [:react_next])
    |> maybe_add_tech(String.contains?(body_lower, "_next/"), [:react_next])
    |> maybe_add_tech(String.contains?(body_lower, "_nuxt/"), [:vue_nuxt])
    |> maybe_add_tech(String.contains?(body_lower, "__nuxt"), [:vue_nuxt])
    |> maybe_add_tech(String.contains?(body_lower, "wp-content"), [:wordpress])
    |> maybe_add_tech(String.contains?(body_lower, "wp-includes"), [:wordpress])
    |> maybe_add_tech(String.contains?(body_lower, "wordpress"), [:wordpress])
    |> maybe_add_tech(String.contains?(body_lower, "django"), [:django_python])
    |> maybe_add_tech(String.contains?(body_lower, "csrfmiddlewaretoken"), [:django_python])
    |> maybe_add_tech(String.contains?(body_lower, "laravel"), [:php_laravel])
    |> maybe_add_tech(String.contains?(body_lower, "laravel_session"), [:php_laravel])
    |> maybe_add_tech(String.contains?(body_lower, "csrf-token"), [:php_laravel])
    |> maybe_add_tech(String.contains?(body_lower, "express"), [:nodejs_express])
  end

  defp detect_from_content(acc, _), do: acc

  defp detect_from_url(acc, url) when is_binary(url) do
    url_lower = String.downcase(url)

    acc
    |> maybe_add_tech(String.contains?(url_lower, "/wp-admin"), [:wordpress])
    |> maybe_add_tech(String.contains?(url_lower, "/wp-content"), [:wordpress])
    |> maybe_add_tech(String.contains?(url_lower, "/admin"), [:django_python])
    |> maybe_add_tech(String.contains?(url_lower, "/api/"), [:nodejs_express, :elixir_phoenix])
    |> maybe_add_tech(String.contains?(url_lower, "/graphql"), [:elixir_phoenix, :nodejs_express])
    |> maybe_add_tech(String.contains?(url_lower, "_next/"), [:react_next])
    |> maybe_add_tech(String.contains?(url_lower, "_nuxt/"), [:vue_nuxt])
  end

  defp detect_from_url(acc, _), do: acc

  defp maybe_add_tech(acc, true, new_techs) when is_list(new_techs), do: new_techs ++ acc
  defp maybe_add_tech(acc, true, new_tech), do: [new_tech | acc]
  defp maybe_add_tech(acc, false, _), do: acc
  defp maybe_add_tech(acc, _, func) when is_function(func), do: func.() ++ acc

  @spec get_wordlist_for_technology(technology()) :: String.t()
  def get_wordlist_for_technology(technology) do
    case technology do
      :elixir_phoenix -> "wordlists/elixir-phoenix.txt"
      :vue_nuxt -> "wordlists/vue-nuxt.txt"
      :react_next -> "wordlists/react-next.txt"
      :php_laravel -> "wordlists/php-laravel.txt"
      :wordpress -> "wordlists/wordpress.txt"
      :django_python -> "wordlists/django-python.txt"
      :nodejs_express -> "wordlists/nodejs-express.txt"
      :unknown -> "wordlists/common.txt"
    end
  end

  @spec get_common_extensions_for_technology(technology()) :: list(String.t())
  def get_common_extensions_for_technology(technology) do
    case technology do
      :elixir_phoenix -> [".ex", ".exs", ".eex", ".leex", ".heex"]
      :vue_nuxt -> [".vue", ".js", ".ts", ".json", ".html"]
      :react_next -> [".jsx", ".tsx", ".js", ".ts", ".json", ".html"]
      :php_laravel -> [".php", ".blade.php", ".env", ".htaccess"]
      :wordpress -> [".php", ".html", ".htm", ".xml", ".txt"]
      :django_python -> [".py", ".html", ".json", ".xml", ".txt"]
      :nodejs_express -> [".js", ".ts", ".json", ".html", ".ejs", ".pug"]
      :unknown -> []
    end
  end

  @spec technology_to_string(technology()) :: String.t()
  def technology_to_string(technology) do
    case technology do
      :elixir_phoenix -> "Elixir/Phoenix"
      :vue_nuxt -> "Vue.js/Nuxt.js"
      :react_next -> "React/Next.js"
      :php_laravel -> "PHP/Laravel"
      :wordpress -> "WordPress"
      :django_python -> "Django/Python"
      :nodejs_express -> "Node.js/Express"
      :unknown -> "Unknown"
    end
  end
end

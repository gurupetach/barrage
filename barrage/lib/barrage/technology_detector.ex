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
          | :java_spring
          | :ruby_rails
          | :dotnet_core
          | :cms_drupal
          | :cms_joomla
          | :go_frameworks
          | :ecommerce_platforms
          | :wix
          | :flutter_web
          | :squarespace
          | :webflow
          | :shopify_plus
          | :react_native_web
          | :ionic
          | :unknown

  @spec detect_technology(map()) :: {list(technology()), map()}
  def detect_technology(response) do
    server_info = extract_server_info(response)

    technologies =
      []
      |> detect_from_headers(response.headers)
      |> detect_from_content(response.body)
      |> detect_from_url(response.url)
      |> Enum.uniq()
      |> case do
        [] -> [:unknown]
        techs -> techs
      end

    {technologies, server_info}
  end

  # Legacy function for backward compatibility
  @spec detect_technology_legacy(map()) :: list(technology())
  def detect_technology_legacy(response) do
    {technologies, _server_info} = detect_technology(response)
    technologies
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

          String.contains?(server, "tomcat") ->
            [:java_spring | acc]

          String.contains?(server, "jetty") ->
            [:java_spring | acc]

          String.contains?(server, "puma") ->
            [:ruby_rails | acc]

          String.contains?(server, "passenger") ->
            [:ruby_rails | acc]

          String.contains?(server, "unicorn") ->
            [:ruby_rails | acc]

          String.contains?(server, "kestrel") ->
            [:dotnet_core | acc]

          String.contains?(server, "iis") ->
            [:dotnet_core | acc]

          true ->
            acc
        end
    end
  end

  defp check_framework_headers(acc, headers) do
    acc
    |> check_powered_by_header(headers)
    |> check_generator_header(headers)
  end

  defp check_powered_by_header(acc, headers) do
    case Map.get(headers, "x-powered-by") do
      powered_by when is_binary(powered_by) ->
        cond do
          String.contains?(powered_by, "php") -> [:php_laravel | acc]
          String.contains?(powered_by, "express") -> [:nodejs_express | acc]
          String.contains?(powered_by, "next") -> [:react_next | acc]
          String.contains?(powered_by, "nuxt") -> [:vue_nuxt | acc]
          String.contains?(powered_by, "spring") -> [:java_spring | acc]
          String.contains?(powered_by, "rails") -> [:ruby_rails | acc]
          String.contains?(powered_by, "asp.net") -> [:dotnet_core | acc]
          String.contains?(powered_by, "drupal") -> [:cms_drupal | acc]
          String.contains?(powered_by, "joomla") -> [:cms_joomla | acc]
          String.contains?(powered_by, "shopify") -> [:ecommerce_platforms | acc]
          String.contains?(powered_by, "magento") -> [:ecommerce_platforms | acc]
          true -> acc
        end

      _ ->
        acc
    end
  end

  defp check_generator_header(acc, headers) do
    case Map.get(headers, "x-generator") do
      generator when is_binary(generator) ->
        cond do
          String.contains?(generator, "wordpress") -> [:wordpress | acc]
          String.contains?(generator, "django") -> [:django_python | acc]
          String.contains?(generator, "next") -> [:react_next | acc]
          String.contains?(generator, "nuxt") -> [:vue_nuxt | acc]
          String.contains?(generator, "drupal") -> [:cms_drupal | acc]
          String.contains?(generator, "joomla") -> [:cms_joomla | acc]
          String.contains?(generator, "magento") -> [:ecommerce_platforms | acc]
          String.contains?(generator, "shopify") -> [:ecommerce_platforms | acc]
          true -> acc
        end

      _ ->
        acc
    end
  end

  defp check_technology_headers(acc, headers) do
    acc
    |> maybe_add_tech(Map.has_key?(headers, "x-wp-version"), [:wordpress])
    |> maybe_add_tech(Map.has_key?(headers, "x-pingback"), [:wordpress])
    |> maybe_add_tech(Map.has_key?(headers, "x-nextjs-page"), [:react_next])
    |> maybe_add_tech(Map.has_key?(headers, "x-nuxt-no-ssr"), [:vue_nuxt])
    |> maybe_add_tech(Map.has_key?(headers, "x-phoenix-endpoint"), [:elixir_phoenix])
    |> maybe_add_tech(Map.has_key?(headers, "x-request-id"), [:elixir_phoenix])
    |> maybe_add_tech(Map.has_key?(headers, "x-drupal-cache"), [:cms_drupal])
    |> maybe_add_tech(
      Map.has_key?(headers, "x-generator") and
        String.contains?(Map.get(headers, "x-generator", ""), "drupal"),
      [:cms_drupal]
    )
    |> maybe_add_tech(Map.has_key?(headers, "x-joomla-version"), [:cms_joomla])
    |> maybe_add_tech(Map.has_key?(headers, "x-shopify-stage"), [:ecommerce_platforms])
    |> maybe_add_tech(Map.has_key?(headers, "x-shopify-shop-id"), [:ecommerce_platforms])
    |> maybe_add_tech(Map.has_key?(headers, "x-magento-cache-debug"), [:ecommerce_platforms])
    |> maybe_add_tech(Map.has_key?(headers, "x-wix-request-id"), [:wix])
    |> maybe_add_tech(Map.has_key?(headers, "x-wix-published-version"), [:wix])
    |> maybe_add_tech(Map.has_key?(headers, "x-squarespace-frontend"), [:squarespace])
    |> maybe_add_tech(Map.has_key?(headers, "x-webflow-cache"), [:webflow])
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
    |> maybe_add_tech(String.contains?(body_lower, "spring"), [:java_spring])
    |> maybe_add_tech(String.contains?(body_lower, "thymeleaf"), [:java_spring])
    |> maybe_add_tech(String.contains?(body_lower, "rails"), [:ruby_rails])
    |> maybe_add_tech(String.contains?(body_lower, "ruby on rails"), [:ruby_rails])
    |> maybe_add_tech(String.contains?(body_lower, "asp.net"), [:dotnet_core])
    |> maybe_add_tech(String.contains?(body_lower, "blazor"), [:dotnet_core])
    |> maybe_add_tech(String.contains?(body_lower, "drupal"), [:cms_drupal])
    |> maybe_add_tech(String.contains?(body_lower, "drupal.org"), [:cms_drupal])
    |> maybe_add_tech(String.contains?(body_lower, "joomla"), [:cms_joomla])
    |> maybe_add_tech(String.contains?(body_lower, "joomla.org"), [:cms_joomla])
    |> maybe_add_tech(String.contains?(body_lower, "gin-gonic"), [:go_frameworks])
    |> maybe_add_tech(String.contains?(body_lower, "echo"), [:go_frameworks])
    |> maybe_add_tech(String.contains?(body_lower, "fiber"), [:go_frameworks])
    |> maybe_add_tech(String.contains?(body_lower, "shopify"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "magento"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "woocommerce"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "prestashop"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "opencart"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "bigcommerce"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "salesforce commerce"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "sap commerce"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(body_lower, "adobe commerce"), [:ecommerce_platforms])
    |> maybe_add_tech(
      String.contains?(body_lower, "wix.com") or
        String.contains?(body_lower, "static.wixstatic.com"),
      [:wix]
    )
    |> maybe_add_tech(
      String.contains?(body_lower, "wix-code") or String.contains?(body_lower, "wix-corvid"),
      [:wix]
    )
    |> maybe_add_tech(
      String.contains?(body_lower, "flutter") and String.contains?(body_lower, "canvaskit"),
      [:flutter_web]
    )
    |> maybe_add_tech(String.contains?(body_lower, "flutter-web"), [:flutter_web])
    |> maybe_add_tech(String.contains?(body_lower, "flutter.js"), [:flutter_web])
    |> maybe_add_tech(
      String.contains?(body_lower, "squarespace.com") or
        String.contains?(body_lower, "squarespace-cdn"),
      [:squarespace]
    )
    |> maybe_add_tech(
      String.contains?(body_lower, "webflow") or String.contains?(body_lower, "webflow.com"),
      [:webflow]
    )
    |> maybe_add_tech(
      String.contains?(body_lower, "shopify-plus") or String.contains?(body_lower, "shop.app"),
      [:shopify_plus]
    )
    |> maybe_add_tech(String.contains?(body_lower, "react-native-web"), [:react_native_web])
    |> maybe_add_tech(
      String.contains?(body_lower, "ionic") and String.contains?(body_lower, "capacitor"),
      [:ionic]
    )
    |> maybe_add_tech(String.contains?(body_lower, "@ionic/core"), [:ionic])
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
    |> maybe_add_tech(String.contains?(url_lower, "/sites/default"), [:cms_drupal])
    |> maybe_add_tech(String.contains?(url_lower, "/administrator"), [:cms_joomla])
    |> maybe_add_tech(String.contains?(url_lower, "/shop"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(url_lower, "/cart"), [:ecommerce_platforms])
    |> maybe_add_tech(String.contains?(url_lower, "/checkout"), [:ecommerce_platforms])
    |> maybe_add_tech(
      String.contains?(url_lower, ".wixsite.com") or String.contains?(url_lower, "wix.com"),
      [:wix]
    )
    |> maybe_add_tech(String.contains?(url_lower, ".squarespace.com"), [:squarespace])
    |> maybe_add_tech(
      String.contains?(url_lower, ".webflow.io") or String.contains?(url_lower, "webflow.com"),
      [:webflow]
    )
    |> maybe_add_tech(
      String.contains?(url_lower, ".myshopify.com") or
        String.contains?(url_lower, "shopify-plus"),
      [:shopify_plus]
    )
  end

  defp detect_from_url(acc, _), do: acc

  defp extract_server_info(response) do
    headers_map =
      response.headers
      |> Enum.map(fn {key, value} -> {String.downcase(key), String.downcase(value)} end)
      |> Map.new()

    %{
      server: Map.get(headers_map, "server", "unknown"),
      powered_by: Map.get(headers_map, "x-powered-by", "unknown"),
      ip_address: resolve_ip(response.url),
      hosting_provider: detect_hosting_provider(headers_map),
      os_info: detect_os_from_headers(headers_map),
      cloud_platform: detect_cloud_platform(headers_map),
      database_hints: detect_database_hints(response.body, headers_map),
      security_headers: analyze_security_headers(headers_map)
    }
  end

  defp resolve_ip(url) do
    case URI.parse(url) do
      %{host: host} when is_binary(host) ->
        case :inet.gethostbyname(String.to_charlist(host)) do
          {:ok, {:hostent, _name, _aliases, :inet, _length, [ip | _]}} ->
            ip |> Tuple.to_list() |> Enum.join(".")

          _ ->
            "unknown"
        end

      _ ->
        "unknown"
    end
  end

  defp detect_hosting_provider(headers) do
    cond do
      Map.has_key?(headers, "x-amz-cf-pop") -> "AWS CloudFront"
      Map.has_key?(headers, "x-amz-cf-id") -> "AWS CloudFront"
      Map.has_key?(headers, "x-azure-ref") -> "Microsoft Azure"
      Map.has_key?(headers, "x-goog-meta-") -> "Google Cloud"
      Map.has_key?(headers, "x-served-by") -> "Fastly/Varnish"
      Map.has_key?(headers, "x-cache") -> "CDN/Cache"
      Map.has_key?(headers, "cf-ray") -> "Cloudflare"
      Map.has_key?(headers, "x-github-request-id") -> "GitHub Pages"
      Map.has_key?(headers, "x-vercel-cache") -> "Vercel"
      Map.has_key?(headers, "x-netlify-id") -> "Netlify"
      true -> "unknown"
    end
  end

  defp detect_os_from_headers(headers) do
    server = Map.get(headers, "server", "")

    cond do
      String.contains?(server, "ubuntu") -> "Ubuntu Linux"
      String.contains?(server, "centos") -> "CentOS Linux"
      String.contains?(server, "debian") -> "Debian Linux"
      String.contains?(server, "redhat") -> "Red Hat Linux"
      String.contains?(server, "windows") -> "Windows Server"
      String.contains?(server, "unix") -> "Unix"
      String.contains?(server, "linux") -> "Linux"
      true -> "unknown"
    end
  end

  defp detect_cloud_platform(headers) do
    cond do
      Map.has_key?(headers, "x-amz-cf-pop") or Map.has_key?(headers, "x-amz-cf-id") -> "AWS"
      Map.has_key?(headers, "x-azure-ref") -> "Microsoft Azure"
      Map.has_key?(headers, "x-goog-meta-") -> "Google Cloud Platform"
      Map.has_key?(headers, "x-vercel-cache") -> "Vercel"
      Map.has_key?(headers, "x-netlify-id") -> "Netlify"
      Map.has_key?(headers, "cf-ray") -> "Cloudflare"
      true -> "unknown"
    end
  end

  defp detect_database_hints(body, headers) when is_binary(body) do
    body_lower = String.downcase(body)

    hints = []

    hints = if String.contains?(body_lower, "mysql"), do: ["MySQL" | hints], else: hints
    hints = if String.contains?(body_lower, "postgresql"), do: ["PostgreSQL" | hints], else: hints
    hints = if String.contains?(body_lower, "mongodb"), do: ["MongoDB" | hints], else: hints
    hints = if String.contains?(body_lower, "redis"), do: ["Redis" | hints], else: hints
    hints = if String.contains?(body_lower, "sqlite"), do: ["SQLite" | hints], else: hints
    hints = if String.contains?(body_lower, "oracle"), do: ["Oracle" | hints], else: hints
    hints = if String.contains?(body_lower, "mssql"), do: ["SQL Server" | hints], else: hints

    # Check headers for database-specific information
    hints = if Map.has_key?(headers, "x-mysql-version"), do: ["MySQL" | hints], else: hints

    hints =
      if Map.has_key?(headers, "x-postgres-version"), do: ["PostgreSQL" | hints], else: hints

    Enum.uniq(hints)
  end

  defp detect_database_hints(_, _), do: []

  defp analyze_security_headers(headers) do
    %{
      hsts: Map.has_key?(headers, "strict-transport-security"),
      csp: Map.has_key?(headers, "content-security-policy"),
      xframe: Map.has_key?(headers, "x-frame-options"),
      xcontent: Map.has_key?(headers, "x-content-type-options"),
      referrer_policy: Map.has_key?(headers, "referrer-policy"),
      permissions_policy: Map.has_key?(headers, "permissions-policy")
    }
  end

  defp maybe_add_tech(acc, true, new_techs) when is_list(new_techs), do: new_techs ++ acc
  defp maybe_add_tech(acc, true, new_tech), do: [new_tech | acc]
  defp maybe_add_tech(acc, false, _), do: acc

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
      :java_spring -> "wordlists/java-spring.txt"
      :ruby_rails -> "wordlists/ruby-rails.txt"
      :dotnet_core -> "wordlists/dotnet-core.txt"
      :cms_drupal -> "wordlists/cms-drupal.txt"
      :cms_joomla -> "wordlists/cms-joomla.txt"
      :go_frameworks -> "wordlists/go-frameworks.txt"
      :ecommerce_platforms -> "wordlists/ecommerce-platforms.txt"
      :wix -> "wordlists/common.txt"
      :flutter_web -> "wordlists/common.txt"
      :squarespace -> "wordlists/common.txt"
      :webflow -> "wordlists/common.txt"
      :shopify_plus -> "wordlists/ecommerce-platforms.txt"
      :react_native_web -> "wordlists/react-next.txt"
      :ionic -> "wordlists/common.txt"
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
      :java_spring -> [".java", ".jsp", ".xml", ".properties", ".war", ".jar"]
      :ruby_rails -> [".rb", ".erb", ".yml", ".yaml", ".html", ".css"]
      :dotnet_core -> [".cs", ".cshtml", ".razor", ".dll", ".config", ".json"]
      :cms_drupal -> [".php", ".module", ".install", ".inc", ".yml", ".twig"]
      :cms_joomla -> [".php", ".xml", ".ini", ".sql", ".html", ".css"]
      :go_frameworks -> [".go", ".mod", ".sum", ".yaml", ".yml", ".json"]
      :ecommerce_platforms -> [".php", ".js", ".liquid", ".twig", ".phtml", ".xml"]
      :wix -> [".html", ".js", ".css", ".json"]
      :flutter_web -> [".dart", ".js", ".html", ".css", ".json"]
      :squarespace -> [".html", ".js", ".css", ".json"]
      :webflow -> [".html", ".js", ".css", ".json"]
      :shopify_plus -> [".liquid", ".js", ".css", ".json", ".xml"]
      :react_native_web -> [".js", ".jsx", ".ts", ".tsx", ".json"]
      :ionic -> [".ts", ".js", ".html", ".scss", ".json"]
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
      :java_spring -> "Java/Spring"
      :ruby_rails -> "Ruby/Rails"
      :dotnet_core -> ".NET Core"
      :cms_drupal -> "Drupal CMS"
      :cms_joomla -> "Joomla CMS"
      :go_frameworks -> "Go Framework"
      :ecommerce_platforms -> "E-commerce Platform"
      :wix -> "Wix"
      :flutter_web -> "Flutter Web"
      :squarespace -> "Squarespace"
      :webflow -> "Webflow"
      :shopify_plus -> "Shopify Plus"
      :react_native_web -> "React Native Web"
      :ionic -> "Ionic"
      :unknown -> "Unknown"
    end
  end
end

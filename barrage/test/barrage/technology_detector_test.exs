defmodule Barrage.TechnologyDetectorTest do
  use ExUnit.Case

  describe "detect_technology/1" do
    test "detects Elixir Phoenix from server header" do
      response = %{
        headers: [{"Server", "Cowboy"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :elixir_phoenix in technologies
    end

    test "detects WordPress from content" do
      response = %{
        headers: [],
        body:
          "<html><head><link rel='stylesheet' href='/wp-content/themes/theme.css'></head></html>",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :wordpress in technologies
    end

    test "detects Django from server header" do
      response = %{
        headers: [{"Server", "gunicorn/20.1.0"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :django_python in technologies
    end

    test "detects React Next.js from content" do
      response = %{
        headers: [],
        body: "<script src='/_next/static/chunks/main.js'></script>",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :react_next in technologies
    end

    test "detects multiple technologies" do
      response = %{
        headers: [{"X-Powered-By", "PHP/8.0"}, {"Server", "nginx"}],
        body: "Laravel application",
        url: "https://example.com/api/"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :php_laravel in technologies
      assert :nodejs_express in technologies or :elixir_phoenix in technologies
    end

    test "returns unknown for undetected technologies" do
      response = %{
        headers: [],
        body: "Plain HTML page",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert technologies == [:unknown]
    end

    test "detects Wix from headers" do
      response = %{
        headers: [{"X-Wix-Request-Id", "abc123"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :wix in technologies
    end

    test "detects Wix from content" do
      response = %{
        headers: [],
        body: "static.wixstatic.com content",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :wix in technologies
    end

    test "detects Wix from URL" do
      response = %{
        headers: [],
        body: "",
        url: "https://user.wixsite.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :wix in technologies
    end

    test "detects Flutter Web from content" do
      response = %{
        headers: [],
        body: "flutter canvaskit rendering engine",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :flutter_web in technologies
    end

    test "detects Squarespace from headers" do
      response = %{
        headers: [{"X-Squarespace-Frontend", "1"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :squarespace in technologies
    end

    test "detects Webflow from content" do
      response = %{
        headers: [],
        body: "webflow.com generated site",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :webflow in technologies
    end

    test "detects Ionic from content" do
      response = %{
        headers: [],
        body: "@ionic/core framework",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :ionic in technologies
    end

    test "detects React Native Web from content" do
      response = %{
        headers: [],
        body: "react-native-web components",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :react_native_web in technologies
    end

    test "detects Java Spring from server header" do
      response = %{
        headers: [{"Server", "Apache Tomcat/9.0"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :java_spring in technologies
    end

    test "detects Ruby Rails from server header" do
      response = %{
        headers: [{"Server", "Puma 5.0"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :ruby_rails in technologies
    end

    test "detects .NET Core from server header" do
      response = %{
        headers: [{"Server", "Kestrel"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :dotnet_core in technologies
    end

    test "detects Drupal from headers" do
      response = %{
        headers: [{"X-Drupal-Cache", "MISS"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :cms_drupal in technologies
    end

    test "detects Joomla from headers" do
      response = %{
        headers: [{"X-Joomla-Version", "4.0"}],
        body: "",
        url: "https://example.com"
      }

      {technologies, _server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert :cms_joomla in technologies
    end
  end

  describe "extract_server_info/1" do
    test "extracts comprehensive server information" do
      response = %{
        headers: [
          {"Server", "nginx/1.18.0"},
          {"X-Powered-By", "PHP/8.0"},
          {"CF-Ray", "abc123"},
          {"Strict-Transport-Security", "max-age=31536000"}
        ],
        body: "mysql database connection",
        url: "https://example.com"
      }

      {_technologies, server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert server_info.server == "nginx/1.18.0"
      assert server_info.powered_by == "php/8.0"
      assert server_info.cloud_platform == "Cloudflare"
      assert "MySQL" in server_info.database_hints
      assert server_info.security_headers.hsts == true
      assert server_info.security_headers.csp == false
    end

    test "detects hosting providers" do
      response = %{
        headers: [{"X-Amz-Cf-Pop", "LAX1-C1"}],
        body: "",
        url: "https://example.com"
      }

      {_technologies, server_info} = Barrage.TechnologyDetector.detect_technology(response)

      assert server_info.hosting_provider == "AWS CloudFront"
      assert server_info.cloud_platform == "AWS"
    end
  end

  describe "get_wordlist_for_technology/1" do
    test "returns correct wordlist paths" do
      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:elixir_phoenix) ==
               "wordlists/elixir-phoenix.txt"

      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:wordpress) ==
               "wordlists/wordpress.txt"

      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:unknown) ==
               "wordlists/common.txt"

      # Test new technology wordlists
      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:java_spring) ==
               "wordlists/java-spring.txt"

      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:cms_drupal) ==
               "wordlists/cms-drupal.txt"

      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:wix) ==
               "wordlists/common.txt"

      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:flutter_web) ==
               "wordlists/common.txt"
    end
  end

  describe "get_common_extensions_for_technology/1" do
    test "returns correct extensions for each technology" do
      assert ".ex" in Barrage.TechnologyDetector.get_common_extensions_for_technology(
               :elixir_phoenix
             )

      assert ".php" in Barrage.TechnologyDetector.get_common_extensions_for_technology(
               :php_laravel
             )

      assert ".vue" in Barrage.TechnologyDetector.get_common_extensions_for_technology(:vue_nuxt)

      assert ".jsx" in Barrage.TechnologyDetector.get_common_extensions_for_technology(
               :react_next
             )

      # Test new technology extensions
      assert ".java" in Barrage.TechnologyDetector.get_common_extensions_for_technology(
               :java_spring
             )

      assert ".rb" in Barrage.TechnologyDetector.get_common_extensions_for_technology(:ruby_rails)

      assert ".cs" in Barrage.TechnologyDetector.get_common_extensions_for_technology(
               :dotnet_core
             )

      assert ".dart" in Barrage.TechnologyDetector.get_common_extensions_for_technology(
               :flutter_web
             )

      assert ".liquid" in Barrage.TechnologyDetector.get_common_extensions_for_technology(
               :shopify_plus
             )
    end
  end

  describe "technology_to_string/1" do
    test "converts technology atoms to readable strings" do
      assert Barrage.TechnologyDetector.technology_to_string(:elixir_phoenix) == "Elixir/Phoenix"
      assert Barrage.TechnologyDetector.technology_to_string(:wordpress) == "WordPress"
      assert Barrage.TechnologyDetector.technology_to_string(:unknown) == "Unknown"

      # Test new technology strings
      assert Barrage.TechnologyDetector.technology_to_string(:wix) == "Wix"
      assert Barrage.TechnologyDetector.technology_to_string(:flutter_web) == "Flutter Web"
      assert Barrage.TechnologyDetector.technology_to_string(:squarespace) == "Squarespace"
      assert Barrage.TechnologyDetector.technology_to_string(:webflow) == "Webflow"
      assert Barrage.TechnologyDetector.technology_to_string(:java_spring) == "Java/Spring"
      assert Barrage.TechnologyDetector.technology_to_string(:ruby_rails) == "Ruby/Rails"
      assert Barrage.TechnologyDetector.technology_to_string(:dotnet_core) == ".NET Core"
      assert Barrage.TechnologyDetector.technology_to_string(:ionic) == "Ionic"
    end
  end
end

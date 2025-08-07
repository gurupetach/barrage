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
  end

  describe "get_wordlist_for_technology/1" do
    test "returns correct wordlist paths" do
      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:elixir_phoenix) ==
               "wordlists/elixir-phoenix.txt"

      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:wordpress) ==
               "wordlists/wordpress.txt"

      assert Barrage.TechnologyDetector.get_wordlist_for_technology(:unknown) ==
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
    end
  end

  describe "technology_to_string/1" do
    test "converts technology atoms to readable strings" do
      assert Barrage.TechnologyDetector.technology_to_string(:elixir_phoenix) == "Elixir/Phoenix"
      assert Barrage.TechnologyDetector.technology_to_string(:wordpress) == "WordPress"
      assert Barrage.TechnologyDetector.technology_to_string(:unknown) == "Unknown"
    end
  end
end

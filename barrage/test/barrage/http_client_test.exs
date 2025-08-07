defmodule Barrage.HttpClientTest do
  use ExUnit.Case

  describe "format_response/2" do
    test "formats HTTPoison response correctly" do
      httpoison_response = %HTTPoison.Response{
        status_code: 200,
        headers: [{"Content-Length", "1024"}, {"Content-Type", "text/html"}],
        body: "<html>content</html>"
      }

      url = "http://example.com/test"

      result = Barrage.HttpClient.format_response(httpoison_response, url)

      assert result.status_code == 200
      assert result.url == url
      assert result.content_length == 1024
      assert result.body == "<html>content</html>"
      assert result.headers == [{"Content-Length", "1024"}, {"Content-Type", "text/html"}]
    end

    test "handles missing content-length header" do
      httpoison_response = %HTTPoison.Response{
        status_code: 200,
        headers: [{"Content-Type", "text/html"}],
        body: "content"
      }

      url = "http://example.com/test"

      result = Barrage.HttpClient.format_response(httpoison_response, url)

      assert result.content_length == 0
    end

    test "handles malformed content-length header" do
      httpoison_response = %HTTPoison.Response{
        status_code: 200,
        headers: [{"Content-Length", "invalid"}],
        body: "content"
      }

      url = "http://example.com/test"

      result = Barrage.HttpClient.format_response(httpoison_response, url)

      assert result.content_length == 0
    end
  end

  describe "get_content_length/1" do
    test "extracts content-length from headers" do
      headers = [{"Content-Length", "1024"}, {"Content-Type", "text/html"}]

      result = Barrage.HttpClient.get_content_length(headers)

      assert result == 1024
    end

    test "handles case-insensitive header names" do
      headers = [{"content-length", "2048"}, {"Content-Type", "text/html"}]

      result = Barrage.HttpClient.get_content_length(headers)

      assert result == 2048
    end

    test "returns 0 for missing content-length" do
      headers = [{"Content-Type", "text/html"}]

      result = Barrage.HttpClient.get_content_length(headers)

      assert result == 0
    end

    test "returns 0 for malformed content-length" do
      headers = [{"Content-Length", "not-a-number"}]

      result = Barrage.HttpClient.get_content_length(headers)

      assert result == 0
    end

    test "handles empty headers" do
      result = Barrage.HttpClient.get_content_length([])

      assert result == 0
    end
  end

  describe "build_headers/1" do
    test "builds headers with user agent" do
      config = %{user_agent: "TestAgent/1.0"}

      headers = Barrage.HttpClient.build_headers(config)

      assert headers == [{"User-Agent", "TestAgent/1.0"}]
    end
  end

  describe "build_options/1" do
    test "builds HTTP options from config" do
      config = %{timeout: 5000}

      options = Barrage.HttpClient.build_options(config)

      assert options[:timeout] == 5000
      assert options[:recv_timeout] == 5000
      assert options[:follow_redirect] == false
      assert options[:ssl][:verify] == :verify_none
    end
  end
end

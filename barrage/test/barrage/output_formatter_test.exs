defmodule Barrage.OutputFormatterTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "format_result/2" do
    test "formats successful response" do
      result = %{
        status_code: 200,
        url: "http://example.com/admin",
        content_length: 1024
      }

      config = %{quiet: false}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.format_result(result, config)
        end)

      assert output =~ "200"
      assert output =~ "http://example.com/admin"
      assert output =~ "1.0KB"
    end

    test "formats response with intelligence enabled" do
      result = %{
        status_code: 200,
        url: "http://example.com/config.php",
        content_length: 1024,
        file_type: :php,
        technologies: [:php_laravel],
        security_findings: [:config_file_exposure]
      }

      config = %{quiet: false, intelligent: true}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.format_result(result, config)
        end)

      assert output =~ "200"
      assert output =~ "http://example.com/config.php"
      assert output =~ "[PHP]"
      assert output =~ "[Laravel]"
      assert output =~ "⚠ Config File"
    end

    test "formats response without intelligence" do
      result = %{
        status_code: 200,
        url: "http://example.com/admin",
        content_length: 1024,
        file_type: :php,
        technologies: [:php_laravel],
        security_findings: [:config_file_exposure]
      }

      config = %{quiet: false, intelligent: false}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.format_result(result, config)
        end)

      assert output =~ "200"
      assert output =~ "http://example.com/admin"
      refute output =~ "[PHP]"
      refute output =~ "[Laravel]"
      refute output =~ "⚠"
    end

    test "formats redirect response" do
      result = %{
        status_code: 301,
        url: "http://example.com/moved",
        content_length: 512
      }

      config = %{quiet: false}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.format_result(result, config)
        end)

      assert output =~ "301"
      assert output =~ "http://example.com/moved"
      assert output =~ "512B"
    end

    test "formats error response in verbose mode" do
      result = %{
        status: :error,
        url: "http://example.com/error",
        reason: :timeout
      }

      config = %{quiet: false, verbose: true}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.format_result(result, config)
        end)

      assert output =~ "ERROR"
      assert output =~ "http://example.com/error"
      assert output =~ "timeout"
    end

    test "suppresses error response in non-verbose mode" do
      result = %{
        status: :error,
        url: "http://example.com/error",
        reason: :timeout
      }

      config = %{quiet: false, verbose: false}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.format_result(result, config)
        end)

      assert output == ""
    end

    test "suppresses output in quiet mode" do
      result = %{
        status_code: 200,
        url: "http://example.com/admin",
        content_length: 1024
      }

      config = %{quiet: true}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.format_result(result, config)
        end)

      assert output == ""
    end
  end

  describe "print_summary/2" do
    test "prints summary with results" do
      results = [
        %{status_code: 200, url: "http://example.com/admin"},
        %{status_code: 301, url: "http://example.com/moved"},
        %{status_code: 404, url: "http://example.com/missing1"},
        %{status_code: 404, url: "http://example.com/missing2"}
      ]

      config = %{quiet: false}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.print_summary(results, config)
        end)

      assert output =~ "SCAN COMPLETE"
      assert output =~ "Total requests: 4"
      assert output =~ "Status 200: 1 responses"
      assert output =~ "Status 301: 1 responses"
      assert output =~ "Status 404: 2 responses"
    end

    test "suppresses summary in quiet mode" do
      results = [%{status_code: 200, url: "http://example.com/admin"}]
      config = %{quiet: true}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.print_summary(results, config)
        end)

      assert output == ""
    end

    test "handles empty results" do
      results = []
      config = %{quiet: false}

      output =
        capture_io(fn ->
          Barrage.OutputFormatter.print_summary(results, config)
        end)

      assert output =~ "SCAN COMPLETE"
      assert output =~ "Total requests: 0"
    end
  end

  describe "format_size/1" do
    test "formats bytes" do
      assert Barrage.OutputFormatter.format_size(100) =~ "100B"
    end

    test "formats kilobytes" do
      # 1.5KB
      result = Barrage.OutputFormatter.format_size(1536)
      assert result =~ "1.5KB"
    end

    test "formats megabytes" do
      # 1.5MB
      result = Barrage.OutputFormatter.format_size(1_572_864)
      assert result =~ "1.5MB"
    end

    test "handles non-integer input" do
      result = Barrage.OutputFormatter.format_size(nil)
      assert result == "     -  "
    end
  end

  describe "get_status_color/1" do
    test "returns green for success codes" do
      assert Barrage.OutputFormatter.get_status_color(200) == "\e[32m"
      assert Barrage.OutputFormatter.get_status_color(201) == "\e[32m"
      assert Barrage.OutputFormatter.get_status_color(204) == "\e[32m"
    end

    test "returns yellow for redirect codes" do
      assert Barrage.OutputFormatter.get_status_color(301) == "\e[33m"
      assert Barrage.OutputFormatter.get_status_color(302) == "\e[33m"
      assert Barrage.OutputFormatter.get_status_color(307) == "\e[33m"
    end

    test "returns magenta for auth codes" do
      assert Barrage.OutputFormatter.get_status_color(401) == "\e[35m"
      assert Barrage.OutputFormatter.get_status_color(403) == "\e[35m"
    end

    test "returns red for server error codes" do
      assert Barrage.OutputFormatter.get_status_color(500) == "\e[31m"
    end

    test "returns white for other codes" do
      assert Barrage.OutputFormatter.get_status_color(404) == "\e[37m"
      assert Barrage.OutputFormatter.get_status_color(999) == "\e[37m"
    end
  end
end

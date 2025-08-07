defmodule Barrage.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "parse_extensions/1" do
    test "parses empty string" do
      assert Barrage.CLI.parse_extensions("") == []
    end

    test "parses single extension" do
      assert Barrage.CLI.parse_extensions("php") == [".php"]
    end

    test "parses multiple extensions" do
      assert Barrage.CLI.parse_extensions("php,html,txt") == [".php", ".html", ".txt"]
    end

    test "handles extensions with dots" do
      assert Barrage.CLI.parse_extensions(".php,.html") == [".php", ".html"]
    end

    test "trims whitespace" do
      assert Barrage.CLI.parse_extensions(" php , html , txt ") == [".php", ".html", ".txt"]
    end
  end

  describe "parse_status_codes/1" do
    test "parses default status codes" do
      result = Barrage.CLI.parse_status_codes("200,204,301,302,307,401,403")
      expected = MapSet.new([200, 204, 301, 302, 307, 401, 403])
      assert result == expected
    end

    test "parses custom status codes" do
      result = Barrage.CLI.parse_status_codes("200,404,500")
      expected = MapSet.new([200, 404, 500])
      assert result == expected
    end

    test "handles whitespace" do
      result = Barrage.CLI.parse_status_codes(" 200 , 404 , 500 ")
      expected = MapSet.new([200, 404, 500])
      assert result == expected
    end
  end

  describe "print_banner/1" do
    test "prints banner when not quiet" do
      output =
        capture_io(fn ->
          Barrage.CLI.print_banner(%{quiet: false})
        end)

      assert output =~ "Barrage v0.1.0"
      assert output =~ "Peter Achieng"
    end

    test "does not print banner when quiet" do
      output =
        capture_io(fn ->
          Barrage.CLI.print_banner(%{quiet: true})
        end)

      assert output == ""
    end
  end

  describe "ensure_dot_prefix/1" do
    test "adds dot prefix when missing" do
      assert Barrage.CLI.ensure_dot_prefix("php") == ".php"
    end

    test "keeps dot prefix when present" do
      assert Barrage.CLI.ensure_dot_prefix(".php") == ".php"
    end
  end
end

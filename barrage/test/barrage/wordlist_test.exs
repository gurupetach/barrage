defmodule Barrage.WordlistTest do
  use ExUnit.Case

  @test_wordlist_path "/tmp/test_wordlist.txt"

  setup do
    # Create a temporary wordlist for testing
    File.write!(@test_wordlist_path, """
    admin
    api
    backup

    config
    login
    """)

    on_exit(fn ->
      File.rm(@test_wordlist_path)
    end)
  end

  describe "load/1" do
    test "loads wordlist successfully" do
      {:ok, words} = Barrage.Wordlist.load(@test_wordlist_path)

      expected = ["admin", "api", "backup", "config", "login"]
      assert words == expected
    end

    test "removes empty lines and duplicates" do
      File.write!("/tmp/test_wordlist_with_dupes.txt", """
      admin
      admin
      api

      backup
      api
      """)

      {:ok, words} = Barrage.Wordlist.load("/tmp/test_wordlist_with_dupes.txt")

      expected = ["admin", "api", "backup"]
      assert words == expected

      File.rm("/tmp/test_wordlist_with_dupes.txt")
    end

    test "returns error for non-existent file" do
      {:error, {:file_error, :enoent}} = Barrage.Wordlist.load("/non/existent/file.txt")
    end
  end

  describe "generate_paths/3" do
    test "generates paths without extensions" do
      words = ["admin", "api"]
      extensions = []

      paths = Barrage.Wordlist.generate_paths("http://example.com", words, extensions)

      expected = [
        "http://example.com/admin",
        "http://example.com/api"
      ]

      assert paths == expected
    end

    test "generates paths with extensions" do
      words = ["admin", "api"]
      extensions = [".php", ".html"]

      paths = Barrage.Wordlist.generate_paths("http://example.com", words, extensions)

      expected = [
        "http://example.com/admin",
        "http://example.com/admin.php",
        "http://example.com/admin.html",
        "http://example.com/api",
        "http://example.com/api.php",
        "http://example.com/api.html"
      ]

      assert Enum.sort(paths) == Enum.sort(expected)
    end

    test "normalizes URLs correctly" do
      words = ["admin"]
      extensions = []

      # Test URL with trailing slash
      paths1 = Barrage.Wordlist.generate_paths("http://example.com/", words, extensions)
      assert paths1 == ["http://example.com/admin"]

      # Test URL without protocol
      paths2 = Barrage.Wordlist.generate_paths("example.com", words, extensions)
      assert paths2 == ["http://example.com/admin"]
    end

    test "removes duplicate paths" do
      words = ["admin", "admin"]
      extensions = [".php", ".php"]

      paths = Barrage.Wordlist.generate_paths("http://example.com", words, extensions)

      # Should have unique paths only
      unique_paths = Enum.uniq(paths)
      assert length(paths) == length(unique_paths)
    end
  end

  describe "count_words/1" do
    test "counts words in wordlist" do
      {:ok, count} = Barrage.Wordlist.count_words(@test_wordlist_path)
      assert count == 5
    end

    test "returns error for non-existent file" do
      {:error, _reason} = Barrage.Wordlist.count_words("/non/existent/file.txt")
    end
  end
end

defmodule Barrage.ResponseAnalyzerTest do
  use ExUnit.Case

  describe "analyze/2" do
    test "analyzes successful response" do
      response = %{
        url: "http://example.com/admin",
        status_code: 200,
        content_length: 1024,
        headers: [],
        body: "admin panel content"
      }

      result = Barrage.ResponseAnalyzer.analyze(response, %{})

      assert result.url == "http://example.com/admin"
      assert result.status_code == 200
      assert result.content_length == 1024
      # TODO: Add timing
      assert result.response_time == 0
      assert result.interesting == true
    end

    test "analyzes redirect response" do
      response = %{
        url: "http://example.com/admin",
        status_code: 301,
        content_length: 0,
        headers: [],
        body: ""
      }

      result = Barrage.ResponseAnalyzer.analyze(response, %{})

      assert result.status_code == 301
      assert result.interesting == true
    end

    test "analyzes not found response" do
      response = %{
        url: "http://example.com/nonexistent",
        status_code: 404,
        content_length: 0,
        headers: [],
        body: ""
      }

      result = Barrage.ResponseAnalyzer.analyze(response, %{})

      assert result.status_code == 404
      assert result.interesting == false
    end

    test "analyzes forbidden response with content" do
      response = %{
        url: "http://example.com/forbidden",
        status_code: 403,
        content_length: 1024,
        headers: [],
        body: "forbidden content"
      }

      result = Barrage.ResponseAnalyzer.analyze(response, %{})

      assert result.status_code == 403
      assert result.interesting == true
    end

    test "analyzes forbidden response without content" do
      response = %{
        url: "http://example.com/forbidden",
        status_code: 403,
        content_length: 0,
        headers: [],
        body: ""
      }

      result = Barrage.ResponseAnalyzer.analyze(response, %{})

      assert result.status_code == 403
      assert result.interesting == false
    end
  end

  describe "filter_false_positives/2" do
    test "filters out repetitive responses" do
      results = [
        %{url: "http://example.com/1", status_code: 404, content_length: 100},
        %{url: "http://example.com/2", status_code: 404, content_length: 100},
        %{url: "http://example.com/3", status_code: 404, content_length: 100},
        %{url: "http://example.com/4", status_code: 404, content_length: 100},
        %{url: "http://example.com/5", status_code: 404, content_length: 100},
        %{url: "http://example.com/6", status_code: 404, content_length: 100},
        %{url: "http://example.com/7", status_code: 404, content_length: 100},
        %{url: "http://example.com/8", status_code: 404, content_length: 100},
        %{url: "http://example.com/9", status_code: 404, content_length: 100},
        %{url: "http://example.com/10", status_code: 404, content_length: 100},
        %{url: "http://example.com/11", status_code: 404, content_length: 100},
        %{url: "http://example.com/admin", status_code: 200, content_length: 1024}
      ]

      filtered = Barrage.ResponseAnalyzer.filter_false_positives(results, %{})

      # Should keep the 200 response but filter out the repetitive 404s
      assert length(filtered) == 1
      assert hd(filtered).status_code == 200
    end

    test "keeps diverse responses" do
      results = [
        %{url: "http://example.com/admin", status_code: 200, content_length: 1024},
        %{url: "http://example.com/login", status_code: 301, content_length: 0},
        %{url: "http://example.com/config", status_code: 403, content_length: 512},
        %{url: "http://example.com/missing1", status_code: 404, content_length: 100},
        %{url: "http://example.com/missing2", status_code: 404, content_length: 100}
      ]

      filtered = Barrage.ResponseAnalyzer.filter_false_positives(results, %{})

      # Should keep all diverse responses
      assert length(filtered) == 5
    end

    test "handles empty results" do
      filtered = Barrage.ResponseAnalyzer.filter_false_positives([], %{})
      assert filtered == []
    end
  end
end

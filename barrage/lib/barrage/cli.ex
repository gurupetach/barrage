defmodule Barrage.CLI do
  @moduledoc """
  Command-line interface for Barrage directory brute-forcer.
  """

  alias Barrage.Scanner

  def main(args) do
    args
    |> parse_args()
    |> run()
  end

  defp parse_args(args) do
    Optimus.new!(
      name: "barrage",
      description: "Directory and file brute-forcing tool",
      version: "0.1.0",
      author: "Barrage Team",
      about: "A fast directory/file enumeration tool written in Elixir",
      allow_unknown_args: false,
      parse_double_dash: true,
      args: [
        url: [
          value_name: "URL",
          help: "Target URL (e.g., http://example.com)",
          required: true,
          parser: :string
        ]
      ],
      flags: [
        verbose: [
          short: "-v",
          long: "--verbose",
          help: "Enable verbose output",
          multiple: false
        ],
        quiet: [
          short: "-q",
          long: "--quiet", 
          help: "Suppress banner and errors",
          multiple: false
        ]
      ],
      options: [
        wordlist: [
          value_name: "WORDLIST",
          short: "-w",
          long: "--wordlist",
          help: "Path to wordlist file",
          parser: :string,
          required: false,
          default: "/usr/share/wordlists/dirb/common.txt"
        ],
        threads: [
          value_name: "THREADS",
          short: "-t",
          long: "--threads",
          help: "Number of concurrent threads",
          parser: :integer,
          default: 10
        ],
        extensions: [
          value_name: "EXTENSIONS", 
          short: "-x",
          long: "--extensions",
          help: "File extensions to search for (comma separated)",
          parser: :string,
          default: ""
        ],
        status_codes: [
          value_name: "CODES",
          short: "-s",
          long: "--status-codes",
          help: "Positive status codes (comma separated)",
          parser: :string,
          default: "200,204,301,302,307,401,403"
        ],
        timeout: [
          value_name: "TIMEOUT",
          long: "--timeout",
          help: "HTTP timeout in seconds",
          parser: :integer,
          default: 10
        ],
        user_agent: [
          value_name: "USER_AGENT",
          short: "-a",
          long: "--user-agent",
          help: "User-Agent string",
          parser: :string,
          default: "Barrage/0.1.0"
        ]
      ]
    )
    |> Optimus.parse!(args)
  end

  defp run(%{args: %{url: url}, options: options, flags: flags}) do
    print_banner(flags)
    
    config = %{
      url: url,
      wordlist: options.wordlist,
      threads: options.threads,
      extensions: parse_extensions(options.extensions),
      status_codes: parse_status_codes(options.status_codes),
      timeout: options.timeout * 1000,
      user_agent: options.user_agent,
      verbose: flags.verbose,
      quiet: flags.quiet
    }

    Scanner.run(config)
  end

  defp print_banner(%{quiet: true}), do: :ok
  defp print_banner(_flags) do
    IO.puts """
    =====================================================
    Barrage v0.1.0
    by Your Name
    =====================================================
    """
  end

  defp parse_extensions(""), do: []
  defp parse_extensions(ext_string) do
    ext_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&ensure_dot_prefix/1)
  end

  defp ensure_dot_prefix("." <> _ = ext), do: ext
  defp ensure_dot_prefix(ext), do: "." <> ext

  defp parse_status_codes(codes_string) do
    codes_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> MapSet.new()
  end
end
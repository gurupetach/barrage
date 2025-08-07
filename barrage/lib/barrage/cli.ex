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
          default: "wordlists/common.txt"
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
          help: "HTTP timeout in seconds (default: 5 for faster scanning)",
          parser: :integer,
          default: 5
        ],
        user_agent: [
          value_name: "USER_AGENT",
          short: "-a",
          long: "--user-agent",
          help: "User-Agent string",
          parser: :string,
          default: "Barrage/0.1.0"
        ],
        intelligent: [
          long: "--intelligent",
          help: "Enable intelligent analysis with technology detection and security findings",
          parser: :string,
          default: "true"
        ],
        recursive: [
          short: "-r",
          long: "--recursive",
          help: "Enable recursive directory scanning",
          parser: :string,
          default: "false"
        ],
        max_depth: [
          value_name: "DEPTH",
          long: "--max-depth",
          help: "Maximum recursion depth (default: 3)",
          parser: :integer,
          default: 3
        ]
      ]
    )
    |> Optimus.parse!(args)
  end

  defp run(%{args: %{url: url}, options: options, flags: flags}) do
    print_banner(flags)

    # Legal consent check
    unless flags.quiet do
      require_consent(url)
    end

    config = %{
      url: url,
      wordlist: options.wordlist,
      threads: options.threads,
      extensions: parse_extensions(options.extensions),
      status_codes: parse_status_codes(options.status_codes),
      timeout: options.timeout * 1000,
      user_agent: options.user_agent,
      verbose: flags.verbose,
      quiet: flags.quiet,
      intelligent: options.intelligent == "true",
      recursive: options.recursive == "true",
      max_depth: options.max_depth
    }

    Scanner.run(config)
  end

  defp require_consent(url) do
    IO.puts("📋 CONSENT VERIFICATION:")
    IO.puts("You are about to scan: #{url}")
    IO.puts("")
    IO.puts("Do you confirm that you:")
    IO.puts("• Own this system, OR")
    IO.puts("• Have explicit written authorization to test this system, OR")
    IO.puts("• Are conducting authorized security research?")
    IO.puts("")

    consent =
      IO.gets("Type 'I AGREE' to proceed, or anything else to exit: ")
      |> String.trim()

    unless String.upcase(consent) == "I AGREE" do
      IO.puts("")
      IO.puts("❌ Scanning cancelled - No consent provided")
      IO.puts("Exiting to prevent unauthorized use...")
      System.halt(0)
    end

    IO.puts("")
    IO.puts("✅ Consent recorded - Proceeding with authorized scan...")
    IO.puts("")
  end

  def print_banner(%{quiet: true}), do: :ok

  def print_banner(_flags) do
    IO.puts("""
    =====================================================
    Barrage v0.1.0 - Security Research Tool
    Open Source Project - Educational Use Only
    =====================================================

    ⚠️  LEGAL WARNING:
    • Use ONLY on systems you own or have explicit written permission to test
    • Unauthorized scanning may violate local, state, and international laws
    • Users assume ALL legal responsibility for their actions
    • This tool is for authorized security testing and research ONLY
    • Misuse may result in criminal prosecution and civil liability

    =====================================================
    """)
  end

  def parse_extensions(""), do: []

  def parse_extensions(ext_string) do
    ext_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&ensure_dot_prefix/1)
  end

  def ensure_dot_prefix("." <> _ = ext), do: ext
  def ensure_dot_prefix(ext), do: "." <> ext

  def parse_status_codes(codes_string) do
    codes_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> MapSet.new()
  end
end

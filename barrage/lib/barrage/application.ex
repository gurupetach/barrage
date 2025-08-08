defmodule Barrage.Application do
  @moduledoc """
  Application entry point for Burrito standalone executable.
  """
  
  use Application

  def start(_type, _args) do
    # Get command line arguments from Burrito
    args = case :init.get_plain_arguments() do
      [] -> System.argv()
      plain_args -> Enum.map(plain_args, &to_string/1)
    end

    # Start the CLI with the arguments
    Barrage.CLI.main(args)
    
    # Exit cleanly
    System.halt(0)
  end
end
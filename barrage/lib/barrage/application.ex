defmodule Barrage.Application do
  @moduledoc """
  Application entry point for Burrito standalone executable.
  """
  
  use Application

  def start(_type, _args) do
    # Start required applications
    Application.ensure_all_started(:hackney)
    Application.ensure_all_started(:httpoison)
    
    # Get command line arguments from Burrito
    args = case :init.get_plain_arguments() do
      [] -> System.argv()
      plain_args -> Enum.map(plain_args, &to_string/1)
    end

    # Start the CLI with the arguments in a Task to avoid blocking
    Task.start_link(fn ->
      Barrage.CLI.main(args)
      System.halt(0)
    end)
    
    # Return a supervisor to keep the application running
    {:ok, self()}
  end
end
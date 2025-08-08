defmodule Barrage.MixProject do
  use Mix.Project

  def project do
    [
      app: :barrage,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Barrage.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:optimus, "~> 0.4"},
      {:progress_bar, "~> 3.0"},
      {:jason, "~> 1.4"},
      {:burrito, "~> 1.0"}
    ]
  end

  defp escript do
    [
      main_module: Barrage.CLI,
      name: "barrage"
    ]
  end

  defp releases do
    [
      barrage: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end
end

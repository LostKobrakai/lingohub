defmodule LingoHub.MixProject do
  use Mix.Project

  def project do
    [
      app: :lingo_hub,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      lingo_hub: lingo_hub()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :jason]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.4"},
      {:gettext, "~> 0.16.0", optional: true},
      {:jason, "~> 1.1", optional: true}
    ]
  end

  defp lingo_hub do
    [
      account: "madeit",
      project: "lingohub-elixir"
    ]
  end
end

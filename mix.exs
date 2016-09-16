defmodule Events.Mixfile do
  use Mix.Project

  def project do
    [app: :events,
     version: "0.1.0",
     elixir: "~> 1.3",
     erlc_paths: ["include"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :timex, :httpoison],
     mod: {Events, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:timex, "~> 2.2"},
     {:httpoison, "~> 0.9.0"},
     {:exml, "~> 0.1.0"},
     {:ex_doc, "~> 0.11"},
     {:earmark, ">= 0.0.0"}]
  end
end

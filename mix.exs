defmodule ElixirCrt.MixProject do
  use Mix.Project

  def project do
    [
      app: :ElixirCrt,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/NeuroWinter/ElixirCrt",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:poison, "~> 5.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Alex Manson"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/NeuroWinter/ElixirCrt"},
      name: "crt"
    ]
  end

  defp description() do
    """
    A simple Elixir wrapper for the Crt.sh API, which allows you to get potentially valid subdomains for a given domain.
    """
  end

end

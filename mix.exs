defmodule EcspanseStateMachine.MixProject do
  use Mix.Project

  @name "ECSpanse State Machine"
  @version "0.3.1"
  @description "A State Machine for ECSpanse, an Entity Component System for Elixir"
  @source_url "https://github.com/ketupia/ecspanse_state_machine"

  def project do
    [
      app: :ecspanse_state_machine,
      name: @name,
      description: @description,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,
      # homepage_url: "http://YOUR_PROJECT_HOMEPAGE",

      # hex
      description: @description,
      package: package(),
      docs: docs()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ecspanse, "~> 0.8.1"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:telemetry, ">= 1.2.0"}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "EcspanseStateMachine",
      # logo: "path/to/logo.png",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Kevin Bolton"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end

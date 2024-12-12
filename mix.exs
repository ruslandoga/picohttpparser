defmodule PicoHTTPParser.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/ruslandoga/picohttpparser"

  def project do
    [
      app: :picohttpparser,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:elixir_make | Mix.compilers()],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # hex
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @repo_url}
      ],
      description: "PicoHTTPParser NIF",
      # docs
      name: "PicoHTTPParser",
      docs: [
        source_url: @repo_url,
        source_ref: "v#{@version}",
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"],
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:bench), do: ["lib", "bench/support"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.3", only: :bench},
      {:elixir_make, "~> 0.9.0", runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev}
    ]
  end
end

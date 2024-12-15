defmodule ExUnitExt.MixProject do
  use Mix.Project

  @version "0.1.0-alpha.0"
  @source_url "https://github.com/hrzndhrn/ex_unit_ext"

  def project do
    [
      app: :ex_unit_ext,
      name: "ExUnitExt",
      description: "A small extension to `ExUnit` to add some extra features.",
      version: @version,
      elixir: "~> 1.13",
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      docs: docs(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_file: {:no_warn, "test/support/plts/dialyzer.plt"}
    ]
  end

  def preferred_cli_env do
    [
      carp: :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.github": :test
    ]
  end

  def docs do
    [
      main: "ExUnitExt",
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:conv_case, "~> 0.1"},
      {:escape, "~> 0.2"},
      # dev/test
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:excoveralls, "~> 0.15", only: :test},
      {:recode, "~> 0.7"}
    ]
  end
end

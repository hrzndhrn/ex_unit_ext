defmodule ExUnitExt.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_unit_ext,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:conv_case, "~> 0.1"},
      {:escape, "~> 0.2"},
      # dev/test
      {:recode, "~> 0.7"}
    ]
  end
end

defmodule ExUnitExt.Theme.Ext do
  @moduledoc """
  The `ext` theme.
  """

  use ExUnitExt.Theme

  @signs %{
    success: "·",
    failure: "⛌",
    skipped: "∗",
    invalid: "?"
  }

  def signs(opts) do
    Theme.signs(opts, @signs)
  end

  def print(:suite_started, config) do
    message =
      "Running ExUnit with seed: #{config.seed}, max_cases: #{config.max_cases}"
      |> Theme.indent()
      |> String.pad_trailing(config.width)

    Theme.puts([:reverse, message], config)
    Theme.print_filters(config, :exclude)
    Theme.print_filters(config, :include)
    IO.puts("")
  end

  def print(event, config), do: Theme.print(event, config)
end

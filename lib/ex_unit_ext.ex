defmodule ExUnitExt do
  @formatters %{
    cli: ExUnit.CLIFormatter,
    cli_ext: ExUnitExt.CLIExtFormatter
  }

  def formatter(name, opts \\ [])

  def formatter(:cli, _opts), do: ExUnit.CLIFormatter

  def formatter(name, opts) do
    case Map.fetch(@formatters, name) do
      {:ok, formatter} ->
        Application.put_env(:ex_unit_ex, :config, [{formatter, opts}])
        formatter

      :error ->
        Mix.shell().info([:yellow, "warning: could not find formatter #{inspect(name)}"])
        ExUnit.CLIFormatter
    end
  end
end

defmodule ExUnitExt do
  # @formatters %{
  #   cli: ExUnit.CLIFormatter,
  #   cli_ext: ExUnitExt.CLIExtFormatter,
  #   ext: ExUnitExt.ExtFormatter,
  #   xmas:
  #     {ExUnitExt.CLIExtFormatter,
  #      [
  #        signs: %{
  #          success: "🎄",
  #          failure: "🔥",
  #          skipped: "*",
  #          invalid: "?"
  #        }
  #      ]},
  #   hearts:
  #     {ExUnitExt.CLIExtFormatter,
  #      [
  #        signs: %{
  #          success: ["💚", "💙", "💜", "💛", "❤️ "],
  #          failure: "🐛",
  #          skipped: "🪰",
  #          invalid: "🐞"
  #        }
  #      ]},
  #   heart:
  #     {ExUnitExt.CLIExtFormatter,
  #      [
  #        signs: %{
  #          success: [[:green, "♥ "]],
  #          failure: [[:red, "♥ "]],
  #          skipped: [[:yellow, "♥ "]],
  #          invalid: [[:magenta, "♥ "]]
  #        }
  #      ]},
  #   block:
  #     {ExUnitExt.CLIExtFormatter,
  #      [
  #        signs: %{
  #          success: [[:green, "█"]],
  #          failure: [[:red, "█"]],
  #          skipped: [[:yellow, "█"]],
  #          invalid: [[:magenta, "█"]]
  #        }
  #      ]}
  # }
  #
  # def formatter(name, opts \\ [])
  #
  # def formatter(:cli, _opts), do: ExUnit.CLIFormatter
  #
  # def formatter(name, opts) do
  #   case Map.fetch(@formatters, name) do
  #     {:ok, {formatter, formatter_opts}} ->
  #       opts = Keyword.merge(opts, formatter_opts)
  #       Application.put_env(:ex_unit_ext, :config, opts)
  #       formatter
  #
  #     {:ok, formatter} ->
  #       Application.put_env(:ex_unit_ext, :config, opts)
  #       formatter
  #
  #     :error ->
  #       Mix.shell().info([:yellow, "warning: could not find formatter #{inspect(name)}"])
  #       ExUnit.CLIFormatter
  #   end
  # end
  #
  def hello(term) do
    # term |> to_string() |> dbg(pipe: :skip)

    # term
    # |> to_string()
    # |> String.split("")
    # |> Enum.reverse()
    # |> dbg(pipe: :skip)

    "Hello, #{to_string(term)}!"
  end
end

defmodule Mix.Tasks.ExUnitExt.Test do
  @shortdoc "A wrapper for `mix test`."

  @moduledoc """
  #{@shortdoc}
  """

  use Mix.Task

  def run(args) do
    Mix.Task.run("test", config(args))
  end

  @options [switches: [dbg_log: :boolean, theme: :string]]
  defp config(args) do
    {opts, _rest} = OptionParser.parse!(args, @options)
    opts = Keyword.take(opts, Keyword.keys(@options[:switches]))
    args = delete_switches(args, @options[:switches])

    if opts[:ex_unit] do
      args
    else
      dbg_log = Keyword.get(opts, :dbg_log, false)

      Application.put_env(:ex_unit_ext, :config, opts)
      Application.put_env(:elixir, :dbg_callback, {ExUnitExt.Dbg, :dbg, [[log: dbg_log]]})

      args ++ ["--formatter", "ExUnitExt.CliFormatter"]
    end
  end

  def delete_switches(args, switches) do
    Enum.reduce(switches, args, fn {switch, type}, args ->
      switch = switch |> to_string() |> ConvCase.to_kebab_case()
      args = delete_switch(args, "--#{switch}", type)

      if type == :boolean,
        do: delete_switch(args, "--no-#{switch}", type),
        else: args
    end)
  end

  def delete_switch(args, switch, type, acc \\ [])

  def delete_switch([], _switch, _type, acc), do: Enum.reverse(acc)

  def delete_switch([switch, _value | rest], switch, :string, acc) do
    delete_switch(rest, :string, acc)
  end

  def delete_switch([switch | rest], switch, :boolean, acc) do
    delete_switch(rest, switch, :boolean, acc)
  end

  def delete_switch([item | rest], switch, type, acc) do
    delete_switch(rest, switch, type, [item | acc])
  end
end

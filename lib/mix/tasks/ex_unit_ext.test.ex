defmodule Mix.Tasks.ExUnitExt.Test do
  @shortdoc "A wrapper for `mix test`."

  @moduledoc """
  #{@shortdoc}

  To use `ex_unit_ext.test`, it is recommended to add the alias
  `test:  ex_unit_ext.test` to `mix.exs` and run tests with `mix test` as usual.

  The wrapper supports all options of the `mix test` task.
  """

  use Mix.Task

  @impl true
  def run(args) do
    if Mix.env() != :test do
      Mix.raise("""
      "mix ex_unit_ext.test" is running in the \"#{Mix.env()}\" environment.

      It is recommended to add the alias "test:  ex_unit_ext.test" to "mix.exs"
      and run tests with "mix test" as usual.
      """)
    end

    Mix.Task.run("test", config(args))
  end

  @options [switches: [ex_unit: :boolean, dbg_log: :boolean, theme: :string]]

  @doc false
  def config(args) do
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

  defp delete_switches(args, switches) do
    Enum.reduce(switches, args, fn {switch, type}, args ->
      switch = switch |> to_string() |> ConvCase.to_kebab_case()
      args = delete_switch(args, "--#{switch}", type)

      if type == :boolean,
        do: delete_switch(args, "--no-#{switch}", type),
        else: args
    end)
  end

  defp delete_switch(args, switch, type, acc \\ [])

  defp delete_switch([], _switch, _type, acc), do: Enum.reverse(acc)

  defp delete_switch([switch, _value | rest], switch, :string, acc) do
    delete_switch(rest, :string, acc)
  end

  defp delete_switch([switch | rest], switch, :boolean, acc) do
    delete_switch(rest, switch, :boolean, acc)
  end

  defp delete_switch([item | rest], switch, type, acc) do
    delete_switch(rest, switch, type, [item | acc])
  end
end

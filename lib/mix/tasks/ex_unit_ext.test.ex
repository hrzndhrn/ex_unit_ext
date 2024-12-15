defmodule Mix.Tasks.ExUnitExt.Test do
  @shortdoc "A wrapper for `mix test`."

  @moduledoc """
  #{@shortdoc}

  To use `ex_unit_ext.test`, it is recommended to add the alias
  `test:  ex_unit_ext.test` to `mix.exs` and run tests with `mix test` as usual.

  ```
  # mix.exs
  defmodule My.MixProject do
    use Mix.Project

    def project do
      [
        ...
        aliases: [test: "ex_unit_ext.test"]
      ]
    ...
  end
  ```

  The wrapper supports all options of the `mix test` task.

  When you run your test suite, it prints results as they run with a summary at
  the end. The test suite will print a 'sign' for each test. Successful tests
  are represented by a green `.`, failed tests by a red `?`, skipped tests by a
  yellow `*` and invalid tests by a magenta `?`.

  ```shell
  $ mix test --no-color
  Running ExUnit with seed: 450686, max_cases: 16

  ??*.!...

    1) test greets the community (MyAppTest)
       test/my_app_test.exs:22
       Assertion with == failed
       code:  assert MyApp.hello() == :community
       left:  :world
       right: :community
       stacktrace:
         test/my_app_test.exs:23: (test)

    2) MyApp.FooTest: failure on setup_all callback, all tests have been invalidated
       ** (RuntimeError) setup_all fails
       stacktrace:
         test/my_app_test.exs:31: MyApp.FooTest.__ex_unit_setup_all_0/1
         test/my_app_test.exs:27: MyApp.FooTest.__ex_unit__/2

  Finished in 0.02 seconds (0.00s async, 0.02s sync)
  1 doctest, 7 tests, 1 failure, 2 invalid, 1 skipped
  ```

  ## Command line options

  All `mix test` [commans line options](https://hexdocs.pm/mix/Mix.Tasks.Test.html#module-command-line-options)
  are supported.

  The following options are provided by `ExUnitExt`:

    * `--theme` - specify the theme for the output.
      Available themes are: `"ext"`, `"block"` and `"hearts"`.
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
    delete_switch(rest, switch, :string, acc)
  end

  defp delete_switch([switch | rest], switch, :boolean, acc) do
    delete_switch(rest, switch, :boolean, acc)
  end

  defp delete_switch([item | rest], switch, type, acc) do
    delete_switch(rest, switch, type, [item | acc])
  end
end

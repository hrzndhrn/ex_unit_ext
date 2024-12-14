defmodule ExUnitExt.Theme do
  @moduledoc """
  The default theme for `ExUnitExt`.
  """

  import ExUnit.Formatter,
    only: [format_times: 1, format_filters: 2, format_test_failure: 5, format_test_all_failure: 5]

  alias ExUnitExt.Theme

  @default_colors %{
    # CLI formatter
    success: :green,
    invalid: :yellow,
    skipped: :yellow,
    failure: :red,
    warning: :yellow,
    blank: " ",
    error_info: :red,
    extra_info: :cyan,
    location_info: :faint,
    # diff formatter
    diff_delete: :red,
    diff_delete_whitespace: :red_background,
    diff_insert: :green,
    diff_insert_whitespace: :green_background,
    test_info: "",
    stacktrace_info: "",
    test_module_info: ""
  }

  @default_signs %{success: ".", failure: "!", skipped: "*", invalid: "?"}

  @blank " "

  @themes %{
    "xmas" => Theme.Xmas,
    "hearts" => Theme.Hearts,
    "block" => Theme.Block,
    "ext" => Theme.Ext
  }

  @callback colors(opts :: keyword()) :: map()
  @callback signs(opts :: keyword()) :: map()
  @callback print(event :: atom() | tuple(), config :: map()) :: :ok

  defmacro __using__(_opts) do
    quote do
      alias ExUnitExt.Theme

      @behaviour ExUnitExt.Theme

      defdelegate colors(opts), to: Theme
      defdelegate signs(opts), to: Theme
      defdelegate print(event, config), to: Theme

      defoverridable colors: 1, signs: 1, print: 2
    end
  end

  @doc """
  Returns a printer function for the given theme in `opts`.

  If no theme can be found the default theme is used.
  """
  @spec printer(opts :: keyword()) :: (event :: atom() | tuple() -> :ok)
  def printer(opts) do
    theme = theme(opts[:theme])
    config = config(theme, opts)
    fn event -> theme.print(event, config) end
  end

  defp config(theme, opts) do
    config = %{
      colors: theme.colors(opts),
      signs: theme.signs(opts),
      width: get_terminal_width()
    }

    opts = opts |> Keyword.delete(:colors) |> Enum.into(%{})

    Map.merge(config, opts)
  end

  defp theme(nil), do: Theme

  defp theme(name) do
    case Map.fetch(@themes, name) do
      {:ok, theme} ->
        theme

      :error ->
        info = """
        Theme #{inspect(name)} not found. Falling back to default theme.
        Available themes: "#{@themes |> Map.keys() |> Enum.join(~s|", "|)}"
        """

        Mix.Shell.IO.info([:yellow, info])

        Theme
    end
  end

  @doc """
  Returns a theme module for the given `name` or the default theme.

  If the name can not be found the default theme is returned and a warning is
  printed.
  """
  @spec get(String.t() | nil) :: module()
  def get(nil), do: Theme

  def get(name) do
    case Map.fetch(@themes, name) do
      {:ok, theme} ->
        theme

      :error ->
        Mix.Shell.IO.info([:yellow, "Theme '#{name}' not found. Falling back to default theme.\n"])

        Theme
    end
  end

  @doc """
  Returns a map with default colors merged with the custom colors in `opts`.
  """
  @spec colors(opts :: keyword()) :: map()
  def colors(opts) do
    colors = Enum.into(opts[:colors] || [], %{})

    @default_colors
    |> Map.merge(colors)
    |> Map.put_new(:enabled, IO.ANSI.enabled?())
  end

  @doc """
  Returns a map with default signs merged with the custom signs in `opts`.
  """
  @spec signs(opts :: keyword(), map()) :: map()
  def signs(opts, default \\ @default_signs) do
    signs = opts[:signs] || %{}

    Map.merge(default, signs)
  end

  @doc """
  The default print function for `ExUnitExt.Theme`.
  """
  @spec print(event :: atom() | tuple(), config :: map()) :: :ok
  def print(:suite_started, config) do
    IO.puts("Running ExUnit with seed: #{config.seed}, max_cases: #{config.max_cases}")
    print_filters(config, :exclude)
    print_filters(config, :include)
    IO.puts("")
  end

  def print({:suite_finished, times_us, state}, config) do
    IO.puts("\n")
    print_all_excluded(state, config)
    print_test_failures(state, config)
    print_test_all_failures(state, config)
    print_times(times_us)
    print_slowest_tests(state, times_us.run)
    print_slowest_modules(state, times_us.run)
    print_summary(state, false, config)
  end

  def print({:test_started, test}, config) do
    print_trace_test_start(test, config)
  end

  def print({:test_finished, :success, test}, config) do
    if config.trace do
      print_trace_test_result(test, :success, config)
    else
      print_sign(:success, config)
    end
  end

  def print({:test_finished, :excluded, test}, config) do
    if config.trace, do: IO.puts(trace_test_excluded(test))
  end

  def print({:test_finished, :skipped, test}, config) do
    if config.trace do
      puts([:skipped, trace_test_skipped(test)], config)
    else
      print_sign(:skipped, config)
    end
  end

  def print({:test_finished, :invalid, test}, config) do
    if config.trace do
      puts([:invalid, trace_test_result(test)], config)
    else
      print_sign(:invalid, config)
    end
  end

  def print({:test_finished, :failed, test}, config) do
    if config.trace do
      puts([:failure, trace_test_result(test)], config)
    else
      print_sign(:failure, config)
    end
  end

  def print({:module_started, module}, config) do
    if config.trace do
      IO.puts("\n#{inspect(module.name)} [#{Path.relative_to_cwd(module.file)}]")
    end
  end

  def print(:max_failures_reached, config) do
    write([:failure, "\n--max-failures reached, aborting test suite"], config)
  end

  def print({:sigquit, current, state}, config) do
    IO.write("\n\n")

    if current == [] do
      write([:failure, "Aborting test suite, showing results so far...\n\n"], config)
    else
      write([:failure, "Aborting test suite, the following have not completed:\n\n"], config)
      Enum.each(current, &IO.puts(trace_aborted(&1)))
      write([:failure, "\nShowing results so far...\n\n"], config)
    end

    print_summary(state, true, config)
  end

  ## helpers

  @spec format_us(us :: integer()) :: String.t()
  def format_us(us) do
    us = div(us, 10)

    if us < 10 do
      "0.0#{us}"
    else
      us = div(us, 10)
      "#{div(us, 10)}.#{rem(us, 10)}"
    end
  end

  @spec normalize_us(us :: integer()) :: integer()
  def normalize_us(us) do
    div(us, 1000)
  end

  @spec pluralize(count :: integer(), singular :: String.t()) :: String.t()
  def pluralize(1, singular), do: singular
  def pluralize(_, singular), do: singular |> to_string() |> ExUnit.plural_rule()

  @spec pluralize(count :: integer(), singular :: String.t(), plural :: String.t()) :: String.t()
  def pluralize(1, singular, _plural), do: singular
  def pluralize(_, _singular, plural), do: plural

  @spec format(Escape.ansidata(), map()) :: String.t()
  def format(ansi, config) do
    ansi
    |> Escape.format(theme: config.colors, emit: config.colors.enabled)
    |> IO.iodata_to_binary()
  end

  @spec write(Escape.ansidata(), map()) :: String.t()
  def write(ansi, config) do
    Escape.write(ansi, theme: config.colors, emit: config.colors.enabled)
  end

  @spec puts(Escape.ansidata(), map()) :: String.t()
  def puts(ansi, config) do
    Escape.puts(ansi, theme: config.colors, emit: config.colors.enabled)
  end

  @spec color_doc(Escape.ansicode(), Inspect.Algebra.t(), map()) :: Inspect.Algebra.t()
  def color_doc(escape, doc, config) do
    Escape.color_doc(doc, escape, theme: config.colors, emit: config.colors.enabled)
  end

  defp collect_test_type_counts(%{test_counter: test_counter} = _config) do
    Enum.reduce(test_counter, 0, fn {_, count}, acc ->
      acc + count
    end)
  end

  @spec indent(String.t(), non_neg_integer()) :: String.t()
  def indent(output, indent \\ 1)

  def indent("", _indent), do: ""

  def indent(output, indent) do
    indent = String.duplicate(@blank, indent)
    do_indent(output, indent)
  end

  defp do_indent(output, indent) when is_binary(output) do
    indent <> String.replace(output, "\n", "\n#{indent}")
  end

  defp do_indent(output, indent) when is_list(output) do
    for item <- output, do: do_indent(item, indent)
  end

  defp do_indent(output, _indent), do: output

  defp get_terminal_width do
    case :io.columns() do
      {:ok, width} -> max(40, width)
      _ -> 80
    end
  end

  ## print and format

  @spec print_filters(map(), atom()) :: :ok
  def print_filters(opts, key) do
    case opts[key] do
      [] -> :ok
      filters -> IO.puts(format_filters(filters, key))
    end
  end

  defp print_trace_test_start(test, config) do
    if config.trace do
      IO.write("#{trace_test_started(test)} [#{trace_test_line(test)}]")
    end
  end

  defp print_trace_test_result(test, result, config) do
    puts([result, trace_test_result(test)], config)
  end

  defp print_sign(result, config) when is_atom(result) do
    write([result, sign(result, config)], config)
  end

  defp print_sign(config, state) do
    write([state, sign(state, config)], config)
  end

  defp sign(name, config) do
    sign =
      case config.signs[name] do
        {:random, signs} -> Enum.random(signs)
        sign -> sign
      end

    format(sign, config)
  end

  defp print_all_excluded(state, config) do
    test_type_counts = collect_test_type_counts(state)

    if test_type_counts > 0 && state.excluded_counter == test_type_counts do
      puts([:invalid, "All tests have been excluded."], config)
    end
  end

  defp print_test_failures(state, config) do
    tests = Enum.sort_by(state.failures, fn %{tags: tags} -> {tags.file, tags.line} end)

    for {test, counter} <- Enum.with_index(tests, 1) do
      print_test_failure(test, counter, config)
    end
  end

  defp print_test_failure(%{state: {:failed, failures}} = test, counter, config) do
    test
    |> format_test_failure(
      failures,
      counter,
      config.width,
      &formatter(&1, &2, config)
    )
    |> IO.puts()

    print_logs(test.logs)
  end

  defp print_test_all_failures(state, config) do
    for {test_module, counter} <-
          Enum.with_index(state.module_failures, length(state.failures) + 1) do
      print_test_all_failure(test_module, counter, config)
    end
  end

  defp print_test_all_failure(%{state: {:failed, failures}} = test_module, counter, config) do
    test_module
    |> format_test_all_failure(
      failures,
      counter,
      config.width,
      &formatter(&1, &2, config)
    )
    |> IO.puts()
  end

  defp print_slowest_tests(state, time_us) do
    if state.slowest > 0 do
      IO.puts(format_slowest_tests(state, time_us))
    end
  end

  defp print_slowest_modules(state, time_us) do
    if state.slowest_modules > 0 do
      IO.puts(format_slowest_modules(state, time_us))
    end
  end

  defp print_summary(state, force_failures?, config) do
    formatted_test_type_counts = format_test_type_counts(state)
    test_type_counts = collect_test_type_counts(state)
    failure_pl = pluralize(state.failure_counter, "failure", "failures")

    message =
      "#{formatted_test_type_counts}#{state.failure_counter} #{failure_pl}"
      |> if_true(
        state.excluded_counter > 0,
        &(&1 <> ", #{state.excluded_counter} excluded")
      )
      |> if_true(
        state.invalid_counter > 0,
        &(&1 <> ", #{state.invalid_counter} invalid")
      )
      |> if_true(
        state.skipped_counter > 0,
        &(&1 <> ", " <> format([:skipped, "#{state.skipped_counter} skipped"], config))
      )

    cond do
      state.failure_counter > 0 or force_failures? ->
        puts([:failure, message], config)

      state.invalid_counter > 0 ->
        puts([:invalid, message], config)

      test_type_counts > 0 && state.excluded_counter == test_type_counts ->
        puts([:invalid, message], config)

      true ->
        puts([:success, message], config)
    end
  end

  defp if_true(value, false, _fun), do: value
  defp if_true(value, true, fun), do: fun.(value)

  defp print_logs(""), do: nil

  defp print_logs(output) do
    ["The following output was logged:\n", output]
    |> indent(5)
    |> IO.puts()
  end

  defp print_times(times_us) do
    IO.puts(format_times(times_us))
  end

  # Tracing

  defp trace_test_time(%ExUnit.Test{time: time}) do
    "#{format_us(time)}ms"
  end

  defp trace_test_line(%ExUnit.Test{tags: tags}) do
    "L##{tags.line}"
  end

  defp trace_test_file_line(%ExUnit.Test{tags: tags}) do
    "#{Path.relative_to_cwd(tags.file)}:#{tags.line}"
  end

  defp trace_test_started(test) do
    String.replace("  * #{test.name}", "\n", " ")
  end

  defp trace_test_result(test) do
    "\r#{trace_test_started(test)} (#{trace_test_time(test)}) [#{trace_test_line(test)}]"
  end

  defp trace_test_excluded(test) do
    "\r#{trace_test_started(test)} (excluded) [#{trace_test_line(test)}]"
  end

  defp trace_test_skipped(test) do
    "\r#{trace_test_started(test)} (skipped) [#{trace_test_line(test)}]"
  end

  defp trace_aborted(%ExUnit.Test{} = test) do
    "* #{test.name} [#{trace_test_file_line(test)}]"
  end

  defp trace_aborted(%ExUnit.TestModule{name: name, file: file}) do
    "* #{inspect(name)} [#{Path.relative_to_cwd(file)}]"
  end

  # Diff formatting

  defp formatter(:diff_enabled?, _, config), do: config.colors.enabled

  defp formatter(:diff_delete, doc, config) do
    color_doc(:diff_delete, doc, config)
  end

  defp formatter(:diff_delete_whitespace, doc, config) do
    color_doc(:diff_delete_whitespace, doc, config)
  end

  defp formatter(:diff_insert, doc, config) do
    color_doc(:diff_insert, doc, config)
  end

  defp formatter(:diff_insert_whitespace, doc, config) do
    color_doc(:diff_insert_whitespace, doc, config)
  end

  defp formatter(:blame_diff, msg, config) do
    if config.colors.enabled do
      format([:diff_delete, msg], config)
    else
      "-" <> msg <> "-"
    end
  end

  defp formatter(key, msg, config), do: format([key, msg], config)

  defp format_slowest_tests(%{slowest: slowest, test_timings: timings}, run_us) do
    slowest_tests =
      timings
      |> Enum.sort_by(fn %{time: time} -> -time end)
      |> Enum.take(slowest)

    slowest_us = Enum.reduce(slowest_tests, 0, &(&1.time + &2))
    slowest_time = slowest_us |> normalize_us() |> format_us()
    percentage = Float.round(slowest_us / run_us * 100, 1)

    [
      "\nTop #{slowest} slowest (#{slowest_time}s), #{percentage}% of total time:\n\n"
      | Enum.map(slowest_tests, &format_slow_test/1)
    ]
  end

  defp format_slowest_modules(%{slowest_modules: slowest, test_timings: timings}, run_us) do
    slowest_tests =
      timings
      |> Enum.group_by(
        fn %{module: module, tags: tags} ->
          {module, tags.file}
        end,
        fn %{time: time} -> time end
      )
      |> Enum.into([], fn {{module, trace_test_file_line}, timings} ->
        {module, trace_test_file_line, Enum.sum(timings)}
      end)
      |> Enum.sort_by(fn {_module, _, sum_timings} -> sum_timings end, :desc)
      |> Enum.take(slowest)

    slowest_us =
      Enum.reduce(slowest_tests, 0, fn {_module, _, sum_timings}, acc ->
        acc + sum_timings
      end)

    slowest_time = slowest_us |> normalize_us() |> format_us()
    percentage = Float.round(slowest_us / run_us * 100, 1)

    [
      "\nTop #{slowest} slowest (#{slowest_time}s), #{percentage}% of total time:\n\n"
      | Enum.map(slowest_tests, &format_slow_module/1)
    ]
  end

  defp format_slow_test(%ExUnit.Test{time: time, module: module} = test) do
    "#{trace_test_started(test)} (#{inspect(module)}) (#{format_us(time)}ms) " <>
      "[#{trace_test_file_line(test)}]\n"
  end

  defp format_slow_module({module, test_file_path, timings}) do
    "#{inspect(module)} (#{format_us(timings)}ms)\n [#{Path.relative_to_cwd(test_file_path)}]\n"
  end

  defp format_test_type_counts(%{test_counter: test_counter} = _config) do
    test_counter
    |> Enum.sort()
    |> Enum.map(fn {test_type, count} ->
      type_pluralized = pluralize(count, test_type)
      "#{count} #{type_pluralized}, "
    end)
  end
end

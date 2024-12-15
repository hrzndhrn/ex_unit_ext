defmodule ExUnitExt.CLIExtFormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  version = Version.parse!(System.version())

  if not Version.match?(version, "~> 1.17.0") do
    @moduletag :skip
  end

  describe "formatter" do
    test "receives suite started event" do
      formatter = formatter()

      assert event(formatter, {:suite_started, []}) == """
             Running ExUnit with seed: 77, max_cases: 8\n
             """

      formatter = formatter(include: [:foo])

      assert event(formatter, {:suite_started, []}) == """
             Running ExUnit with seed: 77, max_cases: 8
             Including tags: [:foo]\n
             """

      formatter = formatter(include: [:foo], exclude: [:bar])

      assert event(formatter, {:suite_started, []}) == """
             Running ExUnit with seed: 77, max_cases: 8
             Excluding tags: [:bar]
             Including tags: [:foo]\n
             """
    end

    test "receives suite finished event" do
      formatter = formatter()
      times_us = %{async: nil, run: 11925, load: nil}

      assert event(formatter, {:suite_finished, times_us}) == """
             \n\nFinished in 0.01 seconds (0.00s async, 0.01s sync)
             0 failures
             """

      times_us = %{async: 500_000, run: 1_000_000, load: 100_000}

      assert event(formatter, {:suite_finished, times_us}) == """
             \n\nFinished in 1.1 seconds (0.1s on load, 0.5s async, 0.5s sync)
             0 failures
             """
    end
  end

  defp event(pid, event) do
    capture_io(pid, fn ->
      GenServer.cast(pid, event)
      Process.sleep(10)
    end)
  end

  @default_formatter_opts [
    seed: 77,
    max_cases: 8,
    include: [],
    exclude: [],
    slowest: 0,
    slowest_modules: 0,
    colors: [enabled: false]
  ]
  defp formatter(opts \\ []) do
    opts = Keyword.merge(@default_formatter_opts, opts)
    {:ok, pid} = GenServer.start_link(ExUnitExt.CliFormatter, opts)
    pid
  end
end

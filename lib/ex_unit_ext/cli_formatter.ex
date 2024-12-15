defmodule ExUnitExt.CliFormatter do
  @moduledoc false
  use GenServer

  alias ExUnitExt.Theme

  def init(opts) do
    opts = Keyword.merge(opts, Application.get_env(:ex_unit_ext, :config, []))

    config = %{
      printer: Theme.printer(opts),
      slowest: opts[:slowest] || 0,
      slowest_modules: opts[:slowest_modules] || 0,
      test_counter: %{},
      test_timings: [],
      failures: [],
      module_failures: [],
      failure_counter: 0,
      skipped_counter: 0,
      excluded_counter: 0,
      invalid_counter: 0
    }

    {:ok, config}
  end

  def handle_cast({:suite_started, _opts}, state) do
    print(:suite_started, state)

    {:noreply, state}
  end

  def handle_cast({:suite_finished, times_us}, state) do
    print({:suite_finished, times_us, state}, state)

    {:noreply, state}
  end

  def handle_cast({:test_started, test}, state) do
    print({:test_started, test}, state)

    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, state) do
    print({:test_finished, :success, test}, state)

    state =
      state
      |> update_test_counter(test)
      |> update_test_timings(test)

    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, reason}} = test}, state)
      when is_binary(reason) do
    print({:test_finished, :excluded, test}, state)

    state =
      state
      |> update_test_counter(test)
      |> inc(:excluded_counter)

    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skipped, reason}} = test}, state)
      when is_binary(reason) do
    print({:test_finished, :skipped, test}, state)

    state =
      state
      |> update_test_counter(test)
      |> inc(:skipped_counter)

    {:noreply, state}
  end

  def handle_cast(
        {:test_finished,
         %ExUnit.Test{state: {:invalid, %ExUnit.TestModule{state: {:failed, _}}}} = test},
        state
      ) do
    print({:test_finished, :invalid, test}, state)

    state =
      state
      |> update_test_counter(test)
      |> inc(:invalid_counter)

    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, _failures}} = test}, state) do
    print({:test_finished, :failed, test}, state)

    state =
      state
      |> update_test_counter(test)
      |> add_failure(test)
      |> update_test_timings(test)

    {:noreply, state}
  end

  def handle_cast({:module_started, module}, state) do
    print({:module_started, module}, state)
    {:noreply, state}
  end

  def handle_cast({:module_finished, test_module}, state) do
    state = if test_module.state == nil, do: state, else: add_module_failure(state, test_module)

    {:noreply, state}
  end

  def handle_cast(:max_failures_reached, state) do
    print(:max_failures_reached, state)

    {:noreply, state}
  end

  def handle_cast({:sigquit, current}, state) do
    print({:sigquit, current, state}, state)

    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  defp print(event, %{printer: printer}), do: printer.(event)

  defp update_test_counter(%{test_counter: test_counter} = state, test) do
    test_counter = Map.update(test_counter, test.tags.test_type, 1, fn counter -> counter + 1 end)
    %{state | test_counter: test_counter}
  end

  defp inc(state, counter, amount \\ 1) do
    Map.update!(state, counter, fn value -> value + amount end)
  end

  defp add_failure(state, test) do
    state
    |> inc(:failure_counter)
    |> Map.update!(:failures, fn failures -> [test | failures] end)
  end

  defp add_module_failure(state, test_module) do
    # The failed tests have already contributed to the counter, so we should
    # only add the successful tests to the count
    success_count = Enum.count(test_module.tests, fn %{state: state} -> is_nil(state) end)

    state
    |> inc(:failure_counter, success_count)
    |> Map.update!(:module_failures, fn module_failures -> [test_module | module_failures] end)
  end

  defp update_test_timings(
         %{slowest: slowest, slowest_modules: slowest_modules} = config,
         %ExUnit.Test{} = test
       ) do
    if slowest > 0 or slowest_modules > 0 do
      # Do not store logs, as they are not used for timings and consume memory.
      update_in(config.test_timings, &[%{test | logs: ""} | &1])
    else
      config
    end
  end
end

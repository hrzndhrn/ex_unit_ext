defmodule ExUnitExt.Dbg do
  @moduledoc """
  The `ExUnit.Dbg` module provides a `:dbg_callback` for `Kernel.dbg/2`.
  """

  require Logger

  @spec dbg(Macro.t(), Macro.t(), Macro.Env.t(), keyword()) :: Macro.t()
  def dbg(code, options, %Macro.Env{} = env, opts) do
    case env.context do
      :match ->
        raise ArgumentError,
              "invalid expression in match, dbg is not allowed in patterns " <>
                "such as function clauses, case clauses or on the left side of the = operator"

      :guard ->
        raise ArgumentError,
              "invalid expression in guard, dbg is not allowed in guards. " <>
                "To learn more about guards, visit: https://hexdocs.pm/elixir/patterns-and-guards.html"

      _ ->
        :ok
    end

    header = dbg_format_header(env, opts)

    quote do
      to_debug = unquote(dbg_ast_to_debuggable(code))
      unquote(__MODULE__).__dbg__(unquote(header), to_debug, unquote(options) ++ unquote(opts))
    end
  end

  # Pipelines.
  defp dbg_ast_to_debuggable({:|>, _meta, _args} = pipe_ast) do
    value_var = Macro.unique_var(:value, __MODULE__)
    values_acc_var = Macro.unique_var(:values, __MODULE__)

    [start_ast | rest_asts] = asts = for {ast, 0} <- Macro.unpipe(pipe_ast), do: ast
    rest_asts = Enum.map(rest_asts, &Macro.pipe(value_var, &1, 0))

    initial_acc =
      quote do
        unquote(value_var) = unquote(start_ast)
        unquote(values_acc_var) = [unquote(value_var)]
      end

    values_ast =
      for step_ast <- rest_asts, reduce: initial_acc do
        ast_acc ->
          quote do
            unquote(ast_acc)
            unquote(value_var) = unquote(step_ast)
            unquote(values_acc_var) = [unquote(value_var) | unquote(values_acc_var)]
          end
      end

    quote do
      unquote(values_ast)

      {:pipe, unquote(Macro.escape(asts)), Enum.reverse(unquote(values_acc_var))}
    end
  end

  dbg_decomposed_binary_operators = [:&&, :||, :and, :or]

  # Logic operators.
  defp dbg_ast_to_debuggable({op, _meta, [_left, _right]} = ast)
       when op in unquote(dbg_decomposed_binary_operators) do
    acc_var = Macro.unique_var(:acc, __MODULE__)
    result_var = Macro.unique_var(:result, __MODULE__)

    quote do
      unquote(acc_var) = []
      unquote(dbg_boolean_tree(ast, acc_var, result_var))
      {:logic_op, Enum.reverse(unquote(acc_var))}
    end
  end

  defp dbg_ast_to_debuggable({:case, _meta, [expr, [do: clauses]]} = ast) do
    clauses_returning_index =
      Enum.with_index(clauses, fn {:->, meta, [left, right]}, index ->
        {:->, meta, [left, {right, index}]}
      end)

    quote do
      expr = unquote(expr)

      {result, clause_index} =
        case expr do
          unquote(clauses_returning_index)
        end

      {:case, unquote(Macro.escape(ast)), expr, clause_index, result}
    end
  end

  defp dbg_ast_to_debuggable({:cond, _meta, [[do: clauses]]} = ast) do
    modified_clauses =
      Enum.with_index(clauses, fn {:->, _meta, [[left], right]}, index ->
        hd(
          quote do
            clause_value = unquote(left) ->
              {unquote(Macro.escape(left)), clause_value, unquote(index), unquote(right)}
          end
        )
      end)

    quote do
      {clause_ast, clause_value, clause_index, value} =
        cond do
          unquote(modified_clauses)
        end

      {:cond, unquote(Macro.escape(ast)), clause_ast, clause_value, clause_index, value}
    end
  end

  # Any other AST.
  defp dbg_ast_to_debuggable(ast) do
    quote do: {:value, unquote(Macro.escape(ast)), unquote(ast)}
  end

  # This is a binary operator. We replace the left side with a recursive call to
  # this function to decompose it, and then execute the operation and add it to the acc.
  defp dbg_boolean_tree({op, _meta, [left, right]} = ast, acc_var, result_var)
       when op in unquote(dbg_decomposed_binary_operators) do
    replaced_left = dbg_boolean_tree(left, acc_var, result_var)

    quote do
      unquote(result_var) = unquote(op)(unquote(replaced_left), unquote(right))

      unquote(acc_var) = [
        {unquote(Macro.escape(ast)), unquote(result_var)} | unquote(acc_var)
      ]

      unquote(result_var)
    end
  end

  # This is finally an expression, so we assign "result = expr", add it to the acc, and
  # return the result.
  defp dbg_boolean_tree(ast, acc_var, result_var) do
    quote do
      unquote(result_var) = unquote(ast)
      unquote(acc_var) = [{unquote(Macro.escape(ast)), unquote(result_var)} | unquote(acc_var)]
      unquote(result_var)
    end
  end

  @doc false
  def __dbg__(header_string, to_debug, options) do
    ansi_enabled? = IO.ANSI.enabled?()
    syntax_colors = if ansi_enabled?, do: IO.ANSI.syntax_colors(), else: []
    options = Keyword.merge([width: 80, pretty: true, syntax_colors: syntax_colors], options)

    location = if options[:print_location] == false, do: [], else: [header_string, :reset, "\n"]
    {formatted, result} = dbg_format_ast_to_debug(to_debug, options)
    formatted = IO.ANSI.format([location, formatted], ansi_enabled?)

    if options[:log] do
      :ok = Logger.debug(formatted)
    else
      :ok = IO.write(formatted)
    end

    result
  end

  defp dbg_format_ast_to_debug({:pipe, code_asts, values}, options) do
    result = List.last(values)

    code_strings = Enum.map(code_asts, &to_string_with_colors(&1, options))
    [{first_ast, first_value} | asts_with_values] = Enum.zip(code_strings, values)
    first_formatted = [dbg_format_ast(first_ast), " ", inspect(first_value, options), ?\n]

    rest_formatted =
      Enum.map(asts_with_values, fn {code_ast, value} ->
        [:faint, "|> ", :reset, dbg_format_ast(code_ast), " ", inspect(value, options), ?\n]
      end)

    if options[:pipe] == :skip && length(rest_formatted) > 2 do
      {[first_formatted, :faint, "...\n", List.last(rest_formatted)], result}
    else
      {[first_formatted, rest_formatted], result}
    end
  end

  defp dbg_format_ast_to_debug({:logic_op, components}, options) do
    {_ast, final_value} = List.last(components)

    formatted =
      Enum.map(components, fn {ast, value} ->
        [dbg_format_ast(to_string_with_colors(ast, options)), " ", inspect(value, options), ?\n]
      end)

    {formatted, final_value}
  end

  defp dbg_format_ast_to_debug({:case, ast, expr_value, clause_index, value}, options) do
    {:case, _meta, [expr_ast, _]} = ast

    formatted = [
      dbg_maybe_underline("Case argument", options),
      ":\n",
      dbg_format_ast_with_value(expr_ast, expr_value, options),
      ?\n,
      dbg_maybe_underline("Case expression", options),
      " (clause ##{clause_index + 1} matched):\n",
      dbg_format_ast_with_value(ast, value, options)
    ]

    {formatted, value}
  end

  defp dbg_format_ast_to_debug(
         {:cond, ast, clause_ast, clause_value, clause_index, value},
         options
       ) do
    formatted = [
      dbg_maybe_underline("Cond clause", options),
      " (clause ##{clause_index + 1} matched):\n",
      dbg_format_ast_with_value(clause_ast, clause_value, options),
      ?\n,
      dbg_maybe_underline("Cond expression", options),
      ":\n",
      dbg_format_ast_with_value(ast, value, options)
    ]

    {formatted, value}
  end

  defp dbg_format_ast_to_debug({:value, code_ast, value}, options) do
    {dbg_format_ast_with_value(code_ast, value, options), value}
  end

  defp dbg_format_ast_with_value(ast, value, options) do
    [dbg_format_ast(to_string_with_colors(ast, options)), " ", inspect(value, options), ?\n]
  end

  defp dbg_format_header(env, opts) do
    env = Map.update!(env, :file, &(&1 && Path.relative_to_cwd(&1)))
    [stacktrace_entry] = Macro.Env.stacktrace(env)

    if opts[:log] == true do
      Exception.format_stacktrace_entry(stacktrace_entry)
    else
      "[" <> Exception.format_stacktrace_entry(stacktrace_entry) <> "]"
    end
  end

  defp dbg_maybe_underline(string, options) do
    if options[:syntax_colors] != [] do
      IO.ANSI.format([:underline, string, :reset])
    else
      string
    end
  end

  defp dbg_format_ast(ast) do
    [ast, :faint, " #=>", :reset]
  end

  defp to_string_with_colors(ast, options) do
    options = Keyword.take(options, [:syntax_colors])

    algebra = Code.quoted_to_algebra(ast, options)
    IO.iodata_to_binary(Inspect.Algebra.format(algebra, 98))
  end
end

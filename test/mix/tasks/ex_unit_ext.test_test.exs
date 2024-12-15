defmodule Mix.Tasks.ExUnitExt.TestTest do
  use ExUnit.Case

  alias Mix.Tasks.ExUnitExt.Test

  describe "config/1" do
    test "deletes none ExUnit args" do
      assert Test.config(["--no-color", "--theme", "ext"]) == [
               "--no-color",
               "--formatter",
               "ExUnitExt.CliFormatter"
             ]

      # reset default dbg callback
      Application.put_env(:elixir, :dbg_callback, {Macro, :dbg, []})
    end
  end
end

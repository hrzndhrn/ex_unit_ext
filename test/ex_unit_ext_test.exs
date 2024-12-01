defmodule ExUnitExtTest do
  use ExUnit.Case
  doctest ExUnitExt

  test "greets the world" do
    assert ExUnitExt.hello() == :world
  end
end

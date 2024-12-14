defmodule MyAppTest do
  use ExUnit.Case
  doctest MyApp

  test "greets the world" do
    assert MyApp.hello() == :world
  end

  test "greets the community" do
    assert MyApp.hello() == :community
  end
end

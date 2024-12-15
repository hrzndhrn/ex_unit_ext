defmodule MyAppTest do
  use ExUnit.Case
  doctest MyApp

  test "greets the world" do
    assert MyApp.hello() == :world
  end

  test "greets the world again" do
    assert MyApp.hello() == :world
  end

  test "greets the world and again" do
    assert MyApp.hello() == :world
  end

  @tag :skip
  test "greets the world and ..." do
    assert MyApp.hello() == :world
  end

  test "greets the community" do
    assert MyApp.hello() == :community
  end
end

defmodule MyApp.FooTest do
  use ExUnit.Case

  setup_all do
    raise "setup_all fails"
  end

  test "1 == 1" do
    assert 1 == 1
  end

  test "1 == 2" do
    assert 1 == 2
  end
end

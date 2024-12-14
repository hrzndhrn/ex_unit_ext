defmodule ExUnitExtTest do
  use ExUnit.Case, async: true

  require Logger

  @moduletag :foo

  test "greets the world" do
    assert :world == :world
  end

  @tag :skip
  test "greets the world /2" do
    assert :world == :world
  end

  test "greets the mars" do
    # dbg("warning dbg")
    assert ExUnitExt.hello(:mars) == :fails
  end

  test "whitspace" do
    assert "foobar foo bar" == "foo bar foobar"
  end
  #
  # test "string 1" do
  #   assert "aaa" == "bbb"
  # end
  #
  # test "string 2" do
  #   assert "a" == "aaaa"
  # end
  #
  # test "string 3" do
  #   assert "aaaaa" == "a"
  # end
  #
  # test "list 1" do
  #   assert [1, 2] == [5, 2, 3]
  # end
  #
  # test "list 2" do
  #   assert [1, 2] == [1]
  # end
  #
  # test "exception" do
  #   assert 1 == 1, :one
  # end
  #
  # test "blame" do
  #       Access.fetch(:foo, :bar)
  # end
  #
  # @tag :skip
  # test "greets the skip" do
  #   assert :world == :skip
  # end
end

# defmodule ExUnitExtTest2 do
#   use ExUnit.Case, async: true
#
#   test "greets the moon" do
#     assert :world == :moon
#   end
# end
#
defmodule ExUnitExtTest3 do
  use ExUnit.Case, async: true

  setup_all do
    raise "setup_fall fails"
  end

  test "greets the moon" do
    assert :world == :moon
  end

  test "greets the moon /2" do
    assert :world == :moon
  end
end
#
# defmodule ExUnitExtTest4 do
#   use ExUnit.Case, async: true
#
#   setup do
#     raise "setup fails"
#   end
#
#   test "greets the moon" do
#     assert :world == :moon
#   end
#
#   test "greets the mars" do
#     assert :world == :mars
#   end
# end
#
# defmodule ExUnitExtTest5 do
#   use ExUnit.Case, async: true
#
#   setup_all do
#     raise "setup_all fails"
#   end
#
#   test "greets the world" do
#     assert :world == :world
#   end
#
#   test "greets the moon" do
#     assert :world == :moon
#   end
# end
#
# defmodule ExUnitExtTest6 do
#   use ExUnit.Case
#
#   test "greets the world" do
#     assert :world == :world
#   end
#
#   test "greets the mars" do
#     assert :mars == :mars
#   end
#
#   @tag :skip
#   test "greets the skip" do
#     assert :world == :skip
#   end
# end

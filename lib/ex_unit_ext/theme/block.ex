defmodule ExUnitExt.Theme.Block do
  @moduledoc """
  The `block` theme.

  This theme replaces the `.`, `!`, `*` and `?` by colored blocks.
  """

  use ExUnitExt.Theme

  @signs %{
    success: "█",
    failure: "█",
    skipped: "█",
    invalid: "█"
  }

  @impl true
  def signs(opts), do: Theme.signs(opts, @signs)
end

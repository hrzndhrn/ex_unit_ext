defmodule ExUnitExt.Theme.Xmas do
  @moduledoc false

  use ExUnitExt.Theme


  @signs %{
    success: "🎄",
    failure: "🔥",
    skipped: "*",
    invalid: "?"
  }

  def signs(opts), do: Theme.signs(opts, @signs)
end

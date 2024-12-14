defmodule ExUnitExt.Theme.Hearts do
  @moduledoc false

  use ExUnitExt.Theme


  @signs %{
    success: {:random, ["💚 ", "💙 ", "💜 ", "💛 ", "❤️ "]},
    failure: "🐛 ",
    skipped: "🪰 ",
    invalid: "🐞 "
  }

  def signs(opts), do: Theme.signs(opts, @signs)
end

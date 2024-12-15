defmodule ExUnitExt.Theme.Hearts do
  @moduledoc """
  The `hearts` theme.

  This theme brings even more hearts into the warmest community.
  """

  use ExUnitExt.Theme

  @signs %{
    success: {:random, ["💚 ", "💙 ", "💜 ", "💛 ", "❤️ "]},
    failure: "🐛 ",
    skipped: "🪰 ",
    invalid: "🐞 "
  }

  @impl true
  def signs(opts), do: Theme.signs(opts, @signs)
end

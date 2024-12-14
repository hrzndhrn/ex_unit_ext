defmodule ExUnitExt do
  @moduledoc """
  `ExUnitExt` provides some extensions for `ExUnit`.
  """

  @doc """
  A wrapper for `ExUnit.start/1`.
  """
  @spec start(keyword()) :: :ok
  def start(opts \\ []) do
    ExUnit.start(opts)
  end
end

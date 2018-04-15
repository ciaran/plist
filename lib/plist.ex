defmodule Plist do
  @moduledoc """
  The entry point for reading plist data.
  """

  @type result :: any

  @doc """
  Parse the data provided as an XML or binary format plist,
  depending on the header.
  """
  @spec parse(String.t) :: result
  def parse(data) do
    case String.slice(data, 0, 8) do
      "bplist00" -> Plist.Binary.parse(data)
      "<?xml ve" -> Plist.XML.parse(data)
      _ -> raise "Unknown plist format"
    end
  end
end

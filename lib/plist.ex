defmodule Plist do
  def parse(data) do
    case String.slice(data, 0, 8) do
      "bplist00" -> Plist.Binary.parse(data)
      "<?xml ve" -> Plist.XML.parse(data)
      _ -> raise "Unknown plist format"
    end
  end
end

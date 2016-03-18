defmodule Plist do
  def parse(string) when is_binary(string) do
    handle = File.open!(string, [:ram, :binary])
    contents = parse(handle)
    File.close(handle)
    contents
  end

  def parse(handle) do
    header = IO.binread(handle, 8)
    { :ok, _ } = :file.position(handle, 0)
    case header do
      "bplist00" -> Plist.Binary.parse(handle)
      "<?xml ve" ->  Plist.XML.parse(handle)
      _ -> raise "Unknown plist format"
    end
  end
end

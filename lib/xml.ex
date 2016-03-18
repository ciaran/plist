defmodule Plist.XML do
  require Record

  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText,    Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def parse(handle) do
    xml = IO.binread(handle, :all)

    {doc, _} =
      xml
      |> :binary.bin_to_list
      |> :xmerl_scan.string([{:comments, false}, {:space, :normalize}])

    root =
      doc
      |> xmlElement(:content)
      |> Enum.reject(&empty?/1)
      |> Enum.at(0)

    parse_value(root)
  end

  defp parse_value(element) do
    parse_value(xmlElement(element, :name), xmlElement(element, :content))
  end

  defp parse_value(:string, [text]) do
    text |> xmlText(:value) |> :binary.list_to_bin
  end

  defp parse_value(:date, [text]) do
    parse_value(:string, [text])
  end

  defp parse_value(:true, []), do: true
  defp parse_value(:false, []), do: true

  defp parse_value(:integer, [text]) do
    parse_value(:string, [text]) |> String.to_integer
  end

  defp parse_value(:real, [text]) do
    {value, ""} = parse_value(:string, [text]) |> Float.parse
    value
  end

  defp parse_value(:array, contents) do
    contents
    |> Enum.reject(&empty?/1)
    |> Enum.map(&parse_value/1)
  end

  defp parse_value(:dict, contents) do
    {keys, values} =
      contents
      |> Enum.reject(&empty?/1)
      |> Enum.partition(fn element ->
        xmlElement(element, :name) == :key
      end)

    unless length(keys) == length(values), do:
      raise "Key/value pair mismatch"

    keys =
      keys
      |> Enum.map(fn element ->
        element
        |> xmlElement(:content)
        |> Enum.at(0)
        |> xmlText(:value)
        |> :binary.list_to_bin
      end)

    Enum.zip(keys, values)
    |> Enum.into(%{}, fn {key, element} ->
      {key, parse_value(element)}
    end)
  end

  defp parse_value(:data, [text]) do
    {:ok, data} =
      parse_value(:string, [text])
      |> Base.decode64(ignore: :whitespace)
    data
  end

  defp empty?({:xmlText, _, _, [], ' ', :text}), do: true
  defp empty?(_), do: false
end

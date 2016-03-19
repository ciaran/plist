defmodule Plist.XML do
  require Record

  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText,    Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def parse(xml) do
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

  defp parse_value(:string, list) do
    do_parse_text_nodes(list, "")
  end

  defp parse_value(:date, nodes) do
    parse_value(:string, nodes)
  end

  defp parse_value(:data, nodes) do
    {:ok, data} =
      parse_value(:string, nodes)
      |> Base.decode64
    data
  end

  defp parse_value(:true, []), do: true
  defp parse_value(:false, []), do: true

  defp parse_value(:integer, nodes) do
    parse_value(:string, nodes) |> String.to_integer
  end

  defp parse_value(:real, nodes) do
    {value, ""} = parse_value(:string, nodes) |> Float.parse
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

  defp do_parse_text_nodes([], result), do: result
  defp do_parse_text_nodes([node | list], result) do
    text = node |> xmlText(:value) |> :binary.list_to_bin
    do_parse_text_nodes(list, result <> text)
  end

  defp empty?({:xmlText, _, _, [], ' ', :text}), do: true
  defp empty?(_), do: false
end

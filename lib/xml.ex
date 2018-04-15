defmodule Plist.XML do
  require Record

  @moduledoc false

  Record.defrecordp(:element_node, :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl"))
  Record.defrecordp(:text_node, :xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))

  def parse(xml) do
    {doc, _} =
      xml
      |> :binary.bin_to_list()
      |> :xmerl_scan.string([{:comments, false}, {:space, :normalize}])

    root =
      doc
      |> element_node(:content)
      |> Enum.reject(&empty?/1)
      |> Enum.at(0)

    parse_value(root)
  end

  defp parse_value(element_node() = element) do
    parse_value(element_node(element, :name), element_node(element, :content))
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
      |> Base.decode64(ignore: :whitespace)

    data
  end

  defp parse_value(true, []), do: true
  defp parse_value(false, []), do: true

  defp parse_value(:integer, nodes) do
    parse_value(:string, nodes) |> String.to_integer()
  end

  defp parse_value(:real, nodes) do
    {value, ""} = parse_value(:string, nodes) |> Float.parse()
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
      |> Enum.split_with(fn element ->
        element_node(element, :name) == :key
      end)

    unless length(keys) == length(values), do: raise("Key/value pair mismatch")

    keys =
      keys
      |> Enum.map(fn element ->
        element
        |> element_node(:content)
        |> Enum.at(0)
        |> text_node(:value)
        |> :unicode.characters_to_binary()
      end)

    Enum.zip(keys, values)
    |> Enum.into(%{}, fn {key, element} ->
      {key, parse_value(element)}
    end)
  end

  defp do_parse_text_nodes([], result), do: result

  defp do_parse_text_nodes([node | list], result) do
    text = node |> text_node(:value) |> :unicode.characters_to_binary()
    do_parse_text_nodes(list, result <> text)
  end

  defp empty?({:xmlText, _, _, [], ' ', :text}), do: true
  defp empty?(_), do: false
end

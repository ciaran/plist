defmodule Plist.XML do
  require Record

  @moduledoc false

  Record.defrecordp(
    :element_node,
    :xmlElement,
    Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  )

  Record.defrecordp(
    :text_node,
    :xmlText,
    Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  )

  def decode(xml) do
    {doc, _} =
      xml
      |> :binary.bin_to_list()
      |> :xmerl_scan.string([{:comments, false}])

    root =
      doc
      |> element_node(:content)
      |> Enum.reject(&empty?/1)
      |> Enum.at(0)

    parse_value(root)
  end

  defp parse_value(text_node() = node) do
    if empty?(node) do
      ""
    else
      node |> text_node(:value) |> :unicode.characters_to_binary()
    end
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
  defp parse_value(false, []), do: false

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

    keys
    |> Enum.map(&element_text_value/1)
    |> Enum.zip(values)
    |> Enum.into(%{}, fn {key, element} ->
      {key, parse_value(element)}
    end)
  end

  defp element_text_value(element) do
    case element_node(element, :content) do
      [content_node] ->
        content_node
        |> text_node(:value)
        |> :unicode.characters_to_binary()

      [] ->
        ""
    end
  end

  defp do_parse_text_nodes([], result), do: result

  defp do_parse_text_nodes([node | list], result) do
    text = node |> text_node(:value) |> :unicode.characters_to_binary()
    do_parse_text_nodes(list, result <> text)
  end

  defp empty?({:xmlText, _, _, [], value, :text}) when is_list(value) do
    value |> :unicode.characters_to_binary() |> String.trim() == ""
  end
  defp empty?(_), do: false
end

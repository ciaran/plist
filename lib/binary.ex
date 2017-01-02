# http://fileformats.archiveteam.org/wiki/Property_List/Binary
defmodule Plist.Binary do
  def parse(data) do
    File.open!(data, [:ram, :binary], &do_parse/1)
  end

  defp do_parse(handle) do
    << "bplist00" >> = IO.binread(handle, 8)

    { offset_size, object_ref_size, number_of_objects, root_object, table_offset } = read_trailer(handle)

    { :ok, _ } = :file.position(handle, table_offset)
    offsets = read_offset_list(handle, number_of_objects, offset_size)

    read_object_index(handle, offsets, object_ref_size, root_object)
  end

  defp read_trailer(handle) do
    :file.position(handle, { :eof, -32 })
    trailer = IO.binread(handle, :all)

    <<
      0 :: size(48),
      offset_size :: big-integer-size(8),
      object_ref_size :: big-integer-size(8),
      0 :: size(32),
      number_of_objects :: big-integer-size(32),
      0 :: size(32),
      root_object :: big-integer-size(32),
      0 :: size(32),
      table_offset :: big-integer-size(32)
    >> = trailer
    { offset_size, object_ref_size, number_of_objects, root_object, table_offset }
  end

  defp read_offset_list(handle, count, offset_size) do
    offset_table = IO.binread(handle, count * offset_size)
    for <<offset :: big-integer-size(offset_size)-unit(8) <- offset_table>> do
      offset
    end
  end

  defp read_string(handle, length) do
    IO.binread(handle, length)
  end

  defp read_unicode_string(handle, length) do
    IO.binread(handle, length*2)
    |> :unicode.characters_to_binary(:utf16)
  end

  defp read_index_list(handle, offsets, object_ref_size, indexes) do
    Enum.map(indexes, fn(index) ->
      read_object_index(handle, offsets, object_ref_size, index)
    end)
  end

  defp read_dictionary(_, 0, _, _), do: %{}

  defp read_dictionary(handle, length, offsets, object_ref_size) do
    key_offsets = read_offset_list(handle, length, object_ref_size)
    value_offsets = read_offset_list(handle, length, object_ref_size)

    keys = read_index_list(handle, offsets, object_ref_size, key_offsets)
    values = read_index_list(handle, offsets, object_ref_size, value_offsets)

    Enum.zip(keys, values)
    |> Enum.into(%{})
  end

  def format_date_time({{year, month, day}, {hour, minute, second}}) do
    :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B +0000",
    [year, month, day, hour, minute, second])
      |> List.flatten
      |> to_string
  end

  defp read_date(handle, length) do
    bytes = round(:math.pow(2, length))
    << seconds :: float-size(bytes)-unit(8) >> = IO.binread(handle, bytes)

    apple_epoch = :calendar.datetime_to_gregorian_seconds({{2001,1,1}, {0,0,0}})

    :calendar.gregorian_seconds_to_datetime(round(apple_epoch + seconds))
    |> format_date_time
  end

  defp read_float(handle, length) do
    bytes = round(:math.pow(2, length))
    << value :: float-size(bytes)-unit(8) >> = IO.binread(handle, bytes)
    value
  end

  defp read_integer(handle, length) do
    bytes = round(:math.pow(2, length))
    << value :: big-integer-size(bytes)-unit(8) >> = IO.binread(handle, bytes)
    value
  end

  defp read_array(_, 0, _, _), do: []

  defp read_array(handle, length, offsets, object_ref_size) do
    value_offsets = read_offset_list(handle, length, object_ref_size)
    read_index_list(handle, offsets, object_ref_size, value_offsets)
  end

  defp read_singleton(_, length) do
    case length do
      0  -> nil
      8  -> false
      9  -> true
      15 -> "(fill?)"
      _ -> raise "unknown null type"
    end
  end

  defp read_object(handle, offsets, object_ref_size) do
    <<
      type :: big-integer-size(4),
      length :: big-integer-size(4)
    >> = IO.binread(handle, 1)

    length =
      if type != 0x00 and length == 15 do
        read_object(handle, offsets, object_ref_size)
      else
        length
      end

    case type do
      0x00 -> read_singleton(handle, length)
      0x01 -> read_integer(handle, length)
      0x02 -> read_float(handle, length)
      0x03 -> read_date(handle, length)
      0x04 -> read_string(handle, length)
      0x05 -> read_string(handle, length)
      0x06 -> read_unicode_string(handle, length)
      0x0a -> read_array(handle, length, offsets, object_ref_size)
      0x0d -> read_dictionary(handle, length, offsets, object_ref_size)
    end
  end

  defp read_object_index(handle, offsets, object_ref_size, index) do
    { :ok, _ } = :file.position(handle, Enum.at(offsets, index))
    read_object(handle, offsets, object_ref_size)
  end
end

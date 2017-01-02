defmodule PlistTest do
  use ExUnit.Case
  doctest Plist

  test "basic parsing (binary)" do
    plist = parse_fixture("fixture-binary.plist")

    assert Dict.get(plist, "String") == "foobar"
    assert Dict.get(plist, "Number") == 1234
    assert Dict.get(plist, "Array") == ["A", "B", "C"]
    assert Dict.get(plist, "Date") == "2015-11-17 14:00:59 +0000"
    assert Dict.get(plist, "True") == true
  end

  test "basic parsing (xml)" do
    plist = parse_fixture("fixture-xml.plist")

    assert Dict.get(plist, "String") == "foobar"
    assert Dict.get(plist, "Number") == 1234
    assert Dict.get(plist, "Float") == 1234.1234
    assert Dict.get(plist, "Array") == ["A", "B", "C"]
    assert Dict.get(plist, "Date") == "2015-11-17T14:00:59Z"
    assert Dict.get(plist, "True") == true
    assert Dict.get(plist, "Base64") == <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
    assert Dict.get(plist, "EntityEncoded") == "Foo & Bar"
    assert Dict.get(plist, "UnicσdeKey") == "foobar"
    assert Dict.get(plist, "UnicodeValue") == "© 2008 – 2016"
  end

  defp parse_fixture(filename) do
    [File.cwd!, "test", filename]
    |> Path.join
    |> File.read!
    |> Plist.parse
  end
end

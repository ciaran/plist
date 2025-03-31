defmodule PlistTest do
  use ExUnit.Case
  doctest Plist

  test "basic parsing (binary)" do
    plist = parse_fixture("binary.plist")

    assert Map.get(plist, "String") == "foobar"
    assert Map.get(plist, "Number") == 1234
    assert Map.get(plist, "Array") == ["A", "B", "C"]
    assert Map.get(plist, "Date") == "2015-11-17 14:00:59 +0000"
    assert Map.get(plist, "True") == true
    assert Map.get(plist, "SomeUID")["CF$UID"] == 40
    assert Map.get(plist, "") == ""
    assert Map.get(plist, "DoubleSpaced") == "foo  bar"
  end

  test "basic parsing (xml)" do
    plist = parse_fixture("xml.plist")

    assert Map.get(plist, "String") == "foobar"
    assert Map.get(plist, "Number") == 1234
    assert Map.get(plist, "Float") == 1234.1234
    assert Map.get(plist, "Array") == ["A", "B", "C"]
    assert Map.get(plist, "Date") == "2015-11-17T14:00:59Z"
    assert Map.get(plist, "True") == true
    assert Map.get(plist, "False") == false
    assert Map.get(plist, "Base64") == <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
    assert Map.get(plist, "EntityEncoded") == "Foo & Bar"
    assert Map.get(plist, "UnicσdeKey") == "foobar"
    assert Map.get(plist, "UnicodeValue") == "© 2008 – 2016"
    assert Map.get(plist, "SomeUID")["CF$UID"] == 40
    assert Map.get(plist, "") == ""
    assert Map.get(plist, "DoubleSpaced") == "foo  bar"
  end

  defp parse_fixture(filename) do
    [File.cwd!(), "test", "fixtures", filename]
    |> Path.join()
    |> File.read!()
    |> Plist.decode()
  end
end

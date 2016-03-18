defmodule PlistTest do
  use ExUnit.Case
  doctest Plist

  test "basic parsing (binary)" do
   path = [File.cwd!, "test", "fixture-binary.plist"] |> Path.join
   { :ok, handle } = File.open(path, [:binary])
   data = Plist.parse(handle)

   assert Dict.get(data, "String") == "foobar"
   assert Dict.get(data, "Number") == 1234
   assert Dict.get(data, "Array") == ["A", "B", "C"]
   assert Dict.get(data, "Date") == "2015-11-17 14:00:59 +0000"
   assert Dict.get(data, "True") == true

   File.close(handle)
 end

 test "basic parsing (xml)" do
  path = [File.cwd!, "test", "fixture-xml.plist"] |> Path.join
  { :ok, handle } = File.open(path, [:binary])
  data = Plist.parse(handle)

  assert Dict.get(data, "String") == "foobar"
  assert Dict.get(data, "Number") == 1234
  assert Dict.get(data, "Float") == 1234.1234
  assert Dict.get(data, "Array") == ["A", "B", "C"]
  assert Dict.get(data, "Date") == "2015-11-17T14:00:59Z"
  assert Dict.get(data, "True") == true
  assert Dict.get(data, "Data") == "Hello"

  File.close(handle)
 end

 test "parsing from in-memory data" do
  path = [File.cwd!, "test", "fixture-xml.plist"] |> Path.join
  data = File.read!(path)

  {:ok, handle} = File.open(data, [:ram, :binary])
  data = Plist.parse(handle)

  assert Dict.get(data, "String") == "foobar"

  File.close(handle)
 end
end

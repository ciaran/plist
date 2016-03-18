# Plist

An Elixir library to parse files in Apple's binary property list format.

## Installation

Add plist to your list of dependencies in `mix.exs`:

    def deps do
      [{:plist, "~> 0.0.3"}]
    end

## Usage

    {:ok, handle} = File.open(path, [:binary])
    plist = Plist.parse(handle)
    File.close(handle)

    # To parse in-memory data you can do this:
    plist = Plist.parse("plist string")

# Plist

An Elixir library to parse files in Apple's binary property list format.

## Installation

Add plist to your list of dependencies in `mix.exs`:

    def deps do
      [{:plist, "~> 0.0.5"}]
    end

## Usage

    plist = File.read!(path) |> Plist.parse

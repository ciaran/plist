defmodule Plist.Mixfile do
  use Mix.Project

  def project do
    [app: :plist,
     version: "0.0.3",
     description: "An Elixir library to parse files in Apple's property list formats",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end

  defp package do
    [
      maintainers: ["Ciarán Walsh"],
      licenses: ["MIT"],
      links: %{
        github: "https://github.com/ciaran/plist"
      }
    ]
  end
end

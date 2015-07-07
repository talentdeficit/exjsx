defmodule EXJSX.Mixfile do
  use Mix.Project

  def project do
    [ app: :exjsx,
      version: "3.2.0",
      elixir: ">= 0.13.3",
      description: description,
      package: package,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:jsx]]
  end

  defp deps do
    [{:jsx, "~> 2.6.2"}]
  end
  
  defp description do
    """
    json for elixir
    """
  end
  
  defp package do
    [
      files: ["lib", "LICENSE", "mix.exs", "README.md"],
      contributors: [
        "alisdair sullivan",
        "devin torres",
        "eduardo gurgel",
        "d0rc",
        "igor kapkov",
        "parroty",
        "yurii rashkovskii"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/talentdeficit/exjsx"}
    ]
  end
end

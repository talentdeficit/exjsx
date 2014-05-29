Code.ensure_loaded?(Hex) and Hex.start

defmodule JSEX.Mixfile do
  use Mix.Project

  def project do
    [ app: :jsex,
      version: "2.0.0",
      elixir: ">= 0.13.0",
      description: description,
      package: package,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: ~w(jsx)a]
  end

  defp deps do
    [{:jsx, "~> 2.0"}]
  end
  
  defp description do
    """
    json for elixir
    """
  end
  
  defp package do
    [
      files: ["lib", "ifyouknow.png", "LICENSE", "mix.exs", "README.md"],
      contributors: ["alisdair sullivan"],
      licenses: ["MIT"],
      links: [{"github", "https://github.com/talentdeficit/jsex"}]
    ]
  end
end

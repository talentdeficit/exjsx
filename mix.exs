defmodule JSEX.Mixfile do
  use Mix.Project

  def project do
    [ app: :jsex,
      version: "1.0.0",
      elixir: ">= 0.13.0",
      build_per_environment: false,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: ~w(jsx)a]
  end

  defp deps do
    [{:jsx, github: "talentdeficit/jsx", tag: "v2.0"}]
  end
end

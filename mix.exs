defmodule JSEX.Mixfile do
  use Mix.Project

  def project do
    [ app: :jsex,
      version: "0.2.1",
      build_per_environment: false,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: %w(jsx)a]
  end

  defp deps do
    [{:jsx, github: "talentdeficit/jsx", tag: "v1.4.3"}]
  end
end

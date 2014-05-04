defmodule JSEX.Mixfile do
  use Mix.Project

  def project do
    [ app: :jsex,
      version: "2.0.0",
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
    [{:jsx, ">= 2.0.1", github: "talentdeficit/jsx"}]
  end
end

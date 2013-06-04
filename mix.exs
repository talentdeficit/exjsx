defmodule JSX.Mixfile do
  use Mix.Project

  def project do
    [ app: :exjsx,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  defp deps do
    [{:jsx, github: "talentdeficit/jsx", tag: "v1.4.2"}]
  end
end

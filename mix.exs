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
    [{ :jsx, "1.4.1", git: "https://github.com/talentdeficit/jsx.git" }]
  end
end

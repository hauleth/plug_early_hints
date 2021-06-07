defmodule PlugEarlyHints.MixProject do
  use Mix.Project

  def project do
    [
      app: :plug_early_hints,
      description: "Plug for generating Early Hints response",
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ~w[MIT],
      links: %{
        "GitHub" => "https://github.com/hauleth/plug_early_hints",
        "Early Hints" => "https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/103"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.11"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end

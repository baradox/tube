# Tube

As middleware structure for organizing services ( a plug for services)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add tube to your list of dependencies in `mix.exs`:

        def deps do
          [{:tube, "~> 0.0.1"}]
        end

  2. Ensure tube is started before your application:

        def application do
          [applications: [:tube]]
        end

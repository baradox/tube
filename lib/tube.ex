defmodule Tube do
  @type opts :: tuple | atom | integer | float | [opts]

  defmacro __using__ do
    quote do
      use Tube.Builder
    end
  end

  @callback init(opts) :: opts
  @callback call(Tube.Context.t, opts) :: Tube.Context.t

end

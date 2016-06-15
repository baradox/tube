defmodule Tube do
  @type opts :: tuple | atom | integer | float | [opts]

  defmacro __using__(opts) do
    quote do
      use Tube.Builder, unquote(opts)
      import Tube.Context
    end
  end

  @callback init(opts) :: opts
  @callback call(Tube.Context.t, opts) :: Tube.Context.t

  defmacro call(tube, context, opts \\ []) do
    quote bind_quoted: [tube: tube, context: context, opts: opts] do
      tube.call(Tube.Context.context(context), opts)
    end
  end

  defmacro invoke(tube, context, opts \\ [], key) when is_atom(key) do
    quote bind_quoted: [tube: tube, context: context, opts: opts, key: key] do
      context = tube.call(Tube.Context.context(context), opts)
      Tube.Context.fetch!(context, key)
    end
  end
end

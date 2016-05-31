defmodule Tube.Builder do
  @type tube :: module | atom
  defmacro __using__(opts) do
    quote do
      @behaviour Tube
      @tube_builder_opts unquote(opts)

      def init(opts) do
        opts
      end

      def call(context, opts) do
        tube_builder_call(context, opts)
      end

      defoverridable [init: 1, call: 2]

      import Tube.Context
      import Tube.Builder, only: [tube: 1, tube: 2]

      Module.register_attribute(__MODULE__, :tubes, accumulate: true)
      @before_compile Tube.Builder
    end
  end

  defmacro __before_compile__(env) do
    tubes = Module.get_attribute(env.module, :tubes)
    builder_opts = Module.get_attribute(env.module, :tube_builder_opts)

    if tubes == [] do
      raise "no tube has been defined in #{inspect env.module}"
    end
    {context, body} = Tube.Builder.compile(env, tubes, builder_opts)
    quote do
      defp tube_builder_call(unquote(context), _), do: unquote(body)
    end
  end

  defmacro tube(tube, opts \\ []) do
    quote do
      @tubes {unquote(tube), unquote(opts), true}
    end
  end

  @spec compile(Macro.Env.t, [{tube, Tube.opts, Macro.t}], Keyword.t) :: {Macro.t, Macro.t}
  def compile(env, pipeline, builder_opts) do
    context = quote do: context
    {context, Enum.reduce(pipeline, context, &quote_tube(init_tube(&1), &2, env, builder_opts))}
  end

  defp init_tube({tube, opts, guards}) do
    case Atom.to_char_list(tube) do
      ~c"Elixir." ++ _ -> init_module_tube(tube, opts, guards)
      _                -> init_fun_tube(tube, opts, guards)
    end
  end

  defp init_module_tube(tube, opts, guards) do
    initialized_opts = tube.init(opts)
    if function_exported?(tube, :call, 2) do
      {:module, tube, initialized_opts, guards}
    else
      raise ArgumentError, message: "#{inspect tube} tube must implement call/2"
    end
  end

  defp init_fun_tube(tube, opts, guards) do
    {:function, tube, opts, guards}
  end

  defp quote_tube({tube_type, tube, opts, guards}, acc, env, builder_opts) do
    call = quote_tube_call(tube_type, tube, opts)
    error_message = case tube_type do
      :module -> "expected #{inspect tube}.call/2 to return a Tube.Context"
      :function -> "expected #{tube}/2 to return a Tube.Context"
    end <> ", all tubes must receive a context and return a context"

    quote do
      case unquote(compile_guards(call, guards)) do
        %Tube.Context{halted: true} = context ->
          context
        %Tube.Context{} = context ->
          unquote(acc)
        _ ->
          raise unquote(error_message)
      end
    end
  end

  defp quote_tube_call(:module, tube, opts) do
    quote do: unquote(tube).call(context, unquote(Macro.escape(opts)))
  end

  defp quote_tube_call(:function, tube, opts) do
    quote do: unquote(tube)(context, unquote(Macro.escape(opts)))
  end

  defp compile_guards(call, true) do
    call
  end

  defp compile_guard(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> context
      end
    end
  end
end

defmodule Tube.BuilderTest do

  defmodule Module do
    import Tube.Context

    def init(val) do
      {:init, val}
    end

    def call(context, opts) do
      stack = [{:call, opts}|fetch!(context, :stack)]
      assign(context, :stack, stack)
    end
  end

  defmodule Sample do
    use Tube.Builder
    tube :fun
    tube Module, :opts

    def fun(context, opts) do
      stack = [{:fun, opts}|fetch!(context, :stack)]
      assign(context, :stack, stack)
    end
  end

  defmodule Overridable do
    use Tube.Builder
    import Tube.Context
    def call(context, opts) do
      try do
        super(context, opts)
      catch
        :throw, {:oops, context} -> assign(context, :oops, :caught)
      end
    end

    tube :boom

    def boom(context, opts) do
      context = assign(context, :entered_stack, true)
      throw {:oops, context}
    end
  end

  defmodule Halter do

    use Tube.Builder
    import Tube.Context

    tube :step, :first
    tube :step, :second
    tube :halt_here
    tube :step, :end_of_chain_reached

    def step(context, step), do: assign(context, step, true)

    def halt_here(context, _) do
      context |> assign(:halted, true) |> halt
    end
  end

  use ExUnit.Case, async: true
  import Tube.Context

  test "export init/1 function" do
    assert Sample.init(:ok) == :ok
  end

  test "build stack in the order" do
    context = context(stack: [])
    assert Sample.call(context, []) |> fetch!(:stack) == [call: {:init, :opts}, fun: []]
  end

  test "allows call/2 to be overridden with super" do
    context = context([]) |> Overridable.call([])
    assert fetch!(context, :oops) == :caught
    assert fetch!(context, :entered_stack) == true
  end

  test "halt/2 halts the tube stack" do
    context = context([]) |> Halter.call([])
    assert fetch!(context, :first)
    assert fetch!(context, :second)
    assert fetch!(context, :halted)
    refute get(context, :end_of_chain_reached)
  end
end

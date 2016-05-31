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

  use ExUnit.Case, async: true
  import Tube.Context

  test "export init/1 function" do
    assert Sample.init(:ok) == :ok
  end

  test "build stack in the order" do
    context = context(stack: [])
    assert Sample.call(context, []) |> fetch!(:stack) == [call: {:init, :opts}, fun: []]
  end
end

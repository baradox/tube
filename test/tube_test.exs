defmodule TubeTest do
  use ExUnit.Case

  require Tube
  import Tube.Context

  defmodule Sample do
    import Tube.Context

    def call(context, opts) do
      stack = [{:sample, opts}|fetch!(context, :stack)]
      assign(context, :stack, stack)
    end

  end

  test "export call/3" do
    assert Tube.call(Sample, [stack: []], :opts) |> fetch!(:stack) == [{:sample, :opts}]
  end

  test "export invoke/3" do
    assert Tube.invoke(Sample, [stack: []], :opts, :stack) == [{:sample, :opts}]
  end
end

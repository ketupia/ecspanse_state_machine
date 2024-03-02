defmodule EcspanseStateMachineTest do
  use ExUnit.Case, async: false
  doctest EcspanseStateMachine

  test "greets the world" do
    assert EcspanseStateMachine.hello() == :world
  end
end

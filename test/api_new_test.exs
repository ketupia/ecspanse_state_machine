defmodule ApiNewTest do
  @moduledoc false
  use ExUnit.Case

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  describe "invalid states" do
    # Cannot test these presently since invalid components crash the GenServer

    # test "state without name should raise error" do
    #   states = [[exits: [:yellow]]]

    #   state_machine_spec =
    #     EcspanseStateMachine.new(:red, states)

    #   assert_raise(Ecspanse.Command.Error, fn ->
    #     Ecspanse.Command.spawn_entity!({Ecspanse.Entity, components: [state_machine_spec]})
    #   end)
    # end

    # test "exit state doesn't exist" do
    #   states = [[name: :red, exits: [:yellow]]]

    #   state_machine_spec =
    #     EcspanseStateMachine.new(:red, states)

    #   assert_raise(Ecspanse.Command.Error, fn ->
    #     Ecspanse.Command.spawn_entity!({Ecspanse.Entity, components: [state_machine_spec]})
    #   end)
    # end

    # test "duplicate states" do
    #   states = [
    #     [name: :red, exits: [:yellow]],
    #     [name: :red, exits: [:yellow]],
    #     [name: :yellow, exits: [:red]]
    #   ]

    #   state_machine_spec =
    #     EcspanseStateMachine.new(:red, states)

    #   assert_raise(Ecspanse.Command.Error, fn ->
    #     Ecspanse.Command.spawn_entity!({Ecspanse.Entity, components: [state_machine_spec]})
    #   end)
    # end
  end

  describe "valid cases" do
    test "returns a component spec" do
      initial_state = :initial
      states = [name: initial_state, exits: [initial_state]]

      result = EcspanseStateMachine.new(initial_state, states, auto_start: false)

      assert result != nil
      assert elem(result, 0) == EcspanseStateMachine.Components.StateMachine
      assert Keyword.get(elem(result, 1), :initial_state) == initial_state
      assert Keyword.get(elem(result, 1), :states) == states
      assert Keyword.get(elem(result, 1), :auto_start) == false
    end

    test "sets auto_start to true by default" do
      result = EcspanseStateMachine.new(:initial, [])

      assert Keyword.get(elem(result, 1), :auto_start) == true
    end

    test "sets auto_start to provided value" do
      result = EcspanseStateMachine.new(:initial, [], auto_start: false)

      assert Keyword.get(elem(result, 1), :auto_start) == false
    end
  end
end

defmodule ComponentValidationTest do
  @moduledoc false
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Components.StateMachine
  alias EcspanseStateMachine.Internal.StateSpec
  use ExUnit.Case

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  describe "initial state" do
    test "nil initial state" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine, initial_state: nil)
      end
    end

    test "initial state not in states" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine, initial_state: :foo)
      end
    end
  end

  describe "invalid states" do
    test "Error on no states" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine, states: [])
      end
    end

    test "states must have a name" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine, states: [[exits: [:red]]])
      end
    end

    # [name: :idle, exits: [:patrol, :fight], timeout: 5_000]

    test "exit states must exist" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine,
          states: [[name: :idle, exits: [:patrol]]]
        )
      end
    end

    test "default exit state must exist" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine,
          states: [[name: :idle, exits: [:patrol], default_exit: :fight], [name: :patrol]]
        )
      end
    end

    test "names must be unique" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine,
          states: [[name: :idle], [name: :idle]]
        )
      end
    end
  end

  describe "invalid timeouts" do
    test "timeout with no exit" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, state_machine} = Components.StateMachine.fetch(entity)

      assert_raise Ecspanse.Command.Error, fn ->
        Ecspanse.Command.update_component!(state_machine,
          states: [[name: :idle, timeout: 1000]]
        )
      end
    end
  end
end

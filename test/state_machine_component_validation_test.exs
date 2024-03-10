defmodule StateMachineComponentValidationTest do
  use ExUnit.Case, async: false

  @moduledoc false

  defmodule EcspanseTest do
    @moduledoc false
    use Ecspanse
    @impl true
    def setup(data) do
      data
    end
  end

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  test "manual traffic light spawns" do
    entity =
      Ecspanse.Command.spawn_entity!({
        Ecspanse.Entity,
        components: [
          EcspanseStateMachine.state_machine(
            :red,
            [
              [name: :red, exits_to: [:green, :flashing_red]],
              [name: :flashing_red, exits_to: [:green, :red]],
              [name: :green, exits_to: [:yellow]],
              [name: :yellow, exits_to: [:red]]
            ]
          )
        ]
      })

    assert entity != nil
  end

  describe "state_machine/3" do
    test "returns a component spec" do
      initial_state = :initial
      states = [name: initial_state, exits_to: [initial_state]]

      result = EcspanseStateMachine.state_machine(initial_state, states)

      assert result != nil
      assert elem(result, 0) == EcspanseStateMachine.Components.StateMachine
      assert Keyword.get(elem(result, 1), :initial_state) == initial_state
      assert Keyword.get(elem(result, 1), :states) == states
    end

    test "sets auto_start to true by default" do
      result = EcspanseStateMachine.state_machine(:initial, [])

      assert Keyword.get(elem(result, 1), :auto_start) == true
    end

    test "sets auto_start to provided value" do
      result = EcspanseStateMachine.state_machine(:initial, [], auto_start: false)

      assert Keyword.get(elem(result, 1), :auto_start) == false
    end
  end
end

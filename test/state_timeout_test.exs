defmodule StateTimeoutTest do
  @moduledoc false
  alias EcspanseStateMachine.Internal.StateSpec
  use ExUnit.Case

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  describe "expected timeouts" do
    test ":ok" do
      entity = Examples.traffic_light_with_timeouts()
      EcspanseStateMachine.start(entity)
      EcspanseStateMachine.transition(entity, :red, :green)
      assert {:ok, :green} = EcspanseStateMachine.current_state(entity)

      {:ok, state_machine} = EcspanseStateMachine.Components.StateMachine.fetch(entity)

      state_spec =
        EcspanseStateMachine.Components.StateMachine.get_state_spec(
          state_machine,
          state_machine.current_state
        )

      # wait for the timeout period
      Process.sleep(StateSpec.timeout(state_spec))

      event = %EcspanseStateMachine.Internal.Events.StateTimeout{
        entity_id: entity.id,
        inserted_at: System.monotonic_time()
      }

      EcspanseStateMachine.Internal.Systems.OnStateTimeout.run(event, EcspanseTest.frame(event))

      # expect the state to have been changed from :green to :yellow
      assert {:ok, :yellow} = EcspanseStateMachine.current_state(entity)
    end
  end

  describe "timeout safeties" do
    test "engine stopped - current state becomes nil" do
      # this tests that a timeout event is scheduled and then the state machine is stopped.
      entity = Examples.simple_ai_no_auto_start()
      EcspanseStateMachine.start(entity)
      EcspanseStateMachine.transition(entity, :idle, :fight)
      EcspanseStateMachine.stop(entity)

      event = %EcspanseStateMachine.Internal.Events.StateTimeout{
        entity_id: entity.id,
        inserted_at: System.monotonic_time()
      }

      EcspanseStateMachine.Internal.Systems.OnStateTimeout.run(event, EcspanseTest.frame(event))

      assert {:error, :not_running} = EcspanseStateMachine.current_state(entity)
    end
  end

  test "current state doesn't have a timeout" do
    # this tests that a timeout event is scheduled and then a transition is executed to a state
    # without a timeout.
    entity = Examples.simple_ai_no_auto_start()
    EcspanseStateMachine.start(entity)
    EcspanseStateMachine.transition(entity, :idle, :fight)

    event = %EcspanseStateMachine.Internal.Events.StateTimeout{
      entity_id: entity.id,
      inserted_at: System.monotonic_time()
    }

    EcspanseStateMachine.Internal.Systems.OnStateTimeout.run(event, EcspanseTest.frame(event))

    # fight doesn't have a timeout so the transition should not have changed the state
    assert {:ok, :fight} = EcspanseStateMachine.current_state(entity)
  end
end

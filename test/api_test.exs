defmodule ApiTest do
  @moduledoc false
  use ExUnit.Case

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  describe "current_state" do
    test "not found returns error" do
      assert {:error, :not_found} = EcspanseStateMachine.current_state("1234")
    end

    test "not found no state machine" do
      entity = Examples.no_state_machine()
      {:error, :not_found} = EcspanseStateMachine.current_state(entity)
    end

    test "not found not running" do
      entity = Examples.simple_ai_no_auto_start()
      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())
      assert {:error, :not_running} = EcspanseStateMachine.current_state(entity)
    end

    test "ok initial state" do
      entity = Examples.traffic_light()
      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert {:ok, :red} = EcspanseStateMachine.current_state(entity)
    end
  end

  describe "starting" do
    test "error - already running" do
      entity = Examples.traffic_light()
      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert {:error, :already_running} = EcspanseStateMachine.start(entity.id)
    end

    test "ok - started" do
      entity = Examples.simple_ai_no_auto_start()
      assert :ok = EcspanseStateMachine.start(entity.id)
    end
  end

  describe "stopping" do
    test "error not running" do
      entity = Examples.simple_ai_no_auto_start()
      assert {:error, :not_running} = EcspanseStateMachine.stop(entity.id)
    end

    test "ok stopped" do
      entity = Examples.traffic_light()
      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert :ok = EcspanseStateMachine.stop(entity.id)
    end
  end

  describe "running?" do
    test "ok stopped" do
      entity = Examples.simple_ai_no_auto_start()
      assert {:ok, false} = EcspanseStateMachine.running?(entity)
      EcspanseStateMachine.start(entity)
      assert {:ok, true} = EcspanseStateMachine.running?(entity)
      EcspanseStateMachine.stop(entity.id)
      assert {:ok, false} = EcspanseStateMachine.running?(entity)
    end
  end

  describe "transitions" do
    test "not running returns error" do
      entity = Examples.simple_ai_no_auto_start()
      assert {:error, :not_running} = EcspanseStateMachine.transition(entity.id, :red, :green)
    end

    test "not found returns error" do
      assert {:error, :not_found} = EcspanseStateMachine.transition("1234", :red, :green)
    end

    test "running valid returns :ok, state" do
      entity =
        Examples.traffic_light()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert :ok = EcspanseStateMachine.transition(entity.id, :red, :green)
    end

    test "to a state without a timeout" do
      entity =
        Examples.traffic_light()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert :ok = EcspanseStateMachine.transition(entity.id, :red, :flashing_red)
    end

    test "to a state with a timeout" do
      entity = Examples.traffic_light_with_timeouts()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert :ok = EcspanseStateMachine.transition(entity.id, :red, :green)

      assert {:ok, state_machine} = EcspanseStateMachine.Components.StateMachine.fetch(entity)
      assert state_machine.current_state == :green
      assert state_machine.paused == false
    end

    test "from is not current" do
      entity =
        Examples.traffic_light()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())
      assert {:error, reason} = EcspanseStateMachine.transition(entity.id, :green, :yellow)
      assert reason =~ "does not match the current state"
    end

    test "invalid exit" do
      entity =
        Examples.traffic_light()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())
      assert {:error, reason} = EcspanseStateMachine.transition(entity.id, :red, :yellow)
      assert reason =~ "is not an exit from the current state"
    end

    test "transition to terminal stops" do
      entity = Examples.simple_ai_no_auto_start()
      assert :ok = EcspanseStateMachine.start(entity)
      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert :ok = EcspanseStateMachine.transition(entity, :idle, :fight)
      assert :ok = EcspanseStateMachine.transition(entity, :fight, :die)
      assert {:error, :not_running} = EcspanseStateMachine.stop(entity)
    end
  end

  describe "transitions_to_default_exit" do
    test "running returns :ok, state" do
      entity =
        Examples.traffic_light()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert :ok = EcspanseStateMachine.transition_to_default_exit(entity.id, :red)
      assert {:ok, :green} = EcspanseStateMachine.current_state(entity)
    end

    test "no default " do
      entity =
        Examples.traffic_light()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())

      assert :ok = EcspanseStateMachine.transition_to_default_exit(entity.id, :red)
      assert {:ok, :green} = EcspanseStateMachine.current_state(entity)
    end
  end
end

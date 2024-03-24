defmodule ApiProjectTest do
  @moduledoc false
  use ExUnit.Case

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  describe "errors" do
    test "not found" do
      {:error, :not_found} = EcspanseStateMachine.project("1234")
    end

    test "not found no state machine" do
      entity = Examples.no_state_machine()
      {:error, :not_found} = EcspanseStateMachine.project(entity)
    end
  end

  describe "diagram source" do
    test "initial state not running" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, project} = EcspanseStateMachine.project(entity.id)
      assert false == project.is_running
      assert :idle == project.initial_state
      assert false == project.auto_start
      assert nil == project.current_state
      assert entity.id == project.entity_id
      assert true == project.timer.paused
    end

    test "initial state after started no timeout" do
      entity = Examples.traffic_light()
      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())
      {:ok, project} = EcspanseStateMachine.project(entity.id)
      assert true == project.is_running
      assert :red == project.initial_state
      assert false == project.auto_start
      assert :red == project.current_state
      assert entity.id == project.entity_id
      assert true == project.timer.paused
    end

    test "initial state after started with timeout" do
      entity = Examples.traffic_light_with_timeouts()

      EcspanseStateMachine.Internal.Systems.AutoStarter.run(EcspanseTest.frame())
      {:ok, project} = EcspanseStateMachine.project(entity.id)
      assert true == project.is_running
      assert :red == project.initial_state
      assert false == project.auto_start
      assert :red == project.current_state
      assert entity.id == project.entity_id
      assert false == project.timer.paused
      assert 30_000 == project.timer.duration
    end
  end
end

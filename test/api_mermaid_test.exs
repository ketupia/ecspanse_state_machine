defmodule ApiMermaidTest do
  @moduledoc false
  use ExUnit.Case

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  describe "errors" do
    test "not found - bogus entity_id" do
      {:error, :not_found} = EcspanseStateMachine.format_as_mermaid_diagram("1234")
    end

    test "not found no state machine" do
      entity = Examples.no_state_machine()
      {:error, :not_found} = EcspanseStateMachine.format_as_mermaid_diagram(entity)
    end
  end

  describe "diagram source" do
    test "has diagram type" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, mermaid} = EcspanseStateMachine.format_as_mermaid_diagram(entity.id)
      assert mermaid =~ "stateDiagram-v2"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "has title" do
      entity = Examples.simple_ai_no_auto_start()
      {:ok, mermaid} = EcspanseStateMachine.format_as_mermaid_diagram(entity.id, "Simple AI")
      assert mermaid =~ "title"
      assert mermaid =~ "Simple AI"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "has transitions" do
      entity = Examples.traffic_light()
      {:ok, mermaid} = EcspanseStateMachine.format_as_mermaid_diagram(entity.id)
      assert mermaid =~ "[*] --> red"
      assert mermaid =~ "green --> yellow"
      assert mermaid =~ "yellow --> red"
      assert mermaid =~ "red --> green"
      assert mermaid =~ "red --> flashing_red"
      assert mermaid =~ "flashing_red --> red"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "start and exit states" do
      entity = Examples.simple_ai_no_auto_start()

      {:ok, mermaid} =
        EcspanseStateMachine.format_as_mermaid_diagram(entity.id)

      assert mermaid =~ "[*] --> idle"
      assert mermaid =~ "die --> [*]"
    end

    test "has timeout indicators" do
      entity = Examples.traffic_light_with_timeouts()
      {:ok, mermaid} = EcspanseStateMachine.format_as_mermaid_diagram(entity.id)
      assert mermaid =~ "green --> yellow: ⏲️"
      assert mermaid =~ "yellow --> red: ⏲️"
      assert mermaid =~ "red --> green: ⏲️"
      Ecspanse.Command.despawn_entity!(entity)
    end
  end

  describe "string state names" do
    test "has id block" do
      entity = Examples.mixed_state_names()
      {:ok, mermaid} = EcspanseStateMachine.format_as_mermaid_diagram(entity.id)
      assert mermaid =~ "turn_starts: turn starts"
      assert mermaid =~ "player_1: player 1"
      assert mermaid =~ "player_2: player 2"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "uses ids in transitions" do
      entity = Examples.mixed_state_names()
      {:ok, mermaid} = EcspanseStateMachine.format_as_mermaid_diagram(entity.id)
      assert mermaid =~ "turn_starts --> player_1"
      assert mermaid =~ "player_1 --> player_2"
      assert mermaid =~ "player_2 --> player3"
      Ecspanse.Command.despawn_entity!(entity)
    end
  end
end

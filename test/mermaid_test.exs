defmodule MermaidTest do
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

  describe "traffic light diagram source" do
    test "has diagram type" do
      entity = Examples.traffic_light()
      {:ok, mermaid} = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "stateDiagram-v2"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "has title" do
      entity = Examples.traffic_light()
      {:ok, mermaid} = EcspanseStateMachine.as_mermaid_diagram(entity.id, "traffic light")
      assert mermaid =~ "title"
      assert mermaid =~ "traffic light"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "has transitions" do
      entity = Examples.traffic_light()
      {:ok, mermaid} = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "[*] --> red"
      assert mermaid =~ "green --> yellow"
      assert mermaid =~ "yellow --> red"
      assert mermaid =~ "red --> green"
      assert mermaid =~ "red --> flashing_red"
      assert mermaid =~ "flashing_red --> red"
      Ecspanse.Command.despawn_entity!(entity)
    end
  end

  describe "traffic light with timer diagram source" do
    test "has timeout indicators" do
      entity = Examples.traffic_light_with_timer()
      {:ok, mermaid} = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "green --> yellow: ⏲️"
      assert mermaid =~ "yellow --> red: ⏲️"
      assert mermaid =~ "red --> green: ⏲️"
      Ecspanse.Command.despawn_entity!(entity)
    end
  end

  describe "game turn loop" do
    test "has id block" do
      entity = Examples.game_turn_loop()
      {:ok, mermaid} = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "turn_starts: turn starts"
      assert mermaid =~ "player_1: player 1"
      assert mermaid =~ "player_2: player 2"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "uses ids in transitions" do
      entity = Examples.game_turn_loop()
      {:ok, mermaid} = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "turn_starts --> player_1"
      assert mermaid =~ "player_1 --> player_2"
      assert mermaid =~ "player_2 --> player3"
      Ecspanse.Command.despawn_entity!(entity)
    end
  end
end

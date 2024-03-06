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

  describe "taffic light diagram source" do
    test "has diagram type" do
      entity = Examples.traffic_light()
      mermaid = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "stateDiagram-v2"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "has title" do
      entity = Examples.traffic_light()
      mermaid = EcspanseStateMachine.as_mermaid_diagram(entity.id, "traffic light")
      assert mermaid =~ "title"
      assert mermaid =~ "traffic light"
      Ecspanse.Command.despawn_entity!(entity)
    end

    test "has transitions" do
      entity = Examples.traffic_light()
      mermaid = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "[*] --> red"
      assert mermaid =~ "green --> yellow"
      assert mermaid =~ "yellow --> red"
      assert mermaid =~ "red --> green"
      assert mermaid =~ "red --> flashing_red"
      assert mermaid =~ "flashing_red --> red"
      Ecspanse.Command.despawn_entity!(entity)
    end
  end

  describe "taffic light with timer diagram source" do
    test "has timeout indicators" do
      entity = Examples.traffic_light_with_timer()
      mermaid = EcspanseStateMachine.as_mermaid_diagram(entity.id)
      assert mermaid =~ "green --> yellow: ⏲️"
      assert mermaid =~ "yellow --> red: ⏲️"
      assert mermaid =~ "red --> green: ⏲️"
      Ecspanse.Command.despawn_entity!(entity)
    end
  end
end

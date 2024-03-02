defmodule SpawnGraphTest do
  alias EcspanseStateMachine.SystemsApi
  use ExUnit.Case, async: false

  defmodule DemoTest do
    use Ecspanse
    @impl true
    def setup(data) do
      data
    end
  end

  setup do
    {:ok, _pid} = start_supervised({DemoTest, :test})
    Ecspanse.System.debug()
  end

  test "spawn_graph" do
    {:ok, graph_entity} = SystemsApi.spawn_graph(:traffic_light, :red)
    assert graph_entity != nil
  end
end

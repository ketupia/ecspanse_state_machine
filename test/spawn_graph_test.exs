defmodule SpawnGraphTest do
  alias EcspanseStateMachine.SpawnAttributes.{Graph, Node, Timer}
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

  test "spawn_graph nil" do
    assert {:error, _} = EcspanseStateMachine.spawn_graph(nil)
  end

  test "spawn_graph no nodes" do
    assert {:error, _} =
             EcspanseStateMachine.spawn_graph(%Graph{
               name: :my_graph,
               starting_node: :red,
               nodes: []
             })
  end

  test "spawn_graph missing starting node" do
    assert {:error, _} =
             EcspanseStateMachine.spawn_graph(%Graph{
               name: :my_graph,
               starting_node: :red,
               nodes: [
                 %Node{
                   name: :yellow,
                   exits_to: []
                 }
               ]
             })
  end

  test "spawn_graph missing exit node" do
    assert {:error, _} =
             EcspanseStateMachine.spawn_graph(%Graph{
               name: :my_graph,
               starting_node: :red,
               nodes: [
                 %Node{
                   name: :red,
                   exits_to: [:yellow]
                 }
               ]
             })
  end

  test "spawn_graph missing timer node" do
    assert {:error, _} =
             EcspanseStateMachine.spawn_graph(%Graph{
               name: :my_graph,
               starting_node: :red,
               nodes: [
                 %Node{
                   name: :red,
                   exits_to: [:yellow],
                   timer: %Timer{duration: 3000, exits_to: :green}
                 }
               ]
             })
  end

  test "spawn_graph timer node not in node's exits_to " do
    assert {:error, _} =
             EcspanseStateMachine.spawn_graph(%Graph{
               name: :my_graph,
               starting_node: :red,
               nodes: [
                 %Node{
                   name: :red,
                   exits_to: [:yellow],
                   timer: %Timer{duration: 3000, exits_to: :green}
                 },
                 %Node{
                   name: :yellow,
                   exits_to: [:green]
                 },
                 %Node{
                   name: :green,
                   exits_to: [:red]
                 }
               ]
             })
  end

  test "spawn_graph unreachable node " do
    assert {:error, _} =
             EcspanseStateMachine.spawn_graph(%Graph{
               name: :my_graph,
               starting_node: :red,
               nodes: [
                 %Node{
                   name: :red,
                   exits_to: [:yellow],
                   timer: %Timer{duration: 3000, exits_to: :green}
                 },
                 %Node{
                   name: :yellow,
                   exits_to: []
                 },
                 %Node{
                   name: :green,
                   exits_to: [:red]
                 }
               ]
             })
  end

  test "spawn_graph valid traffic light" do
    assert {:ok, _} =
             EcspanseStateMachine.spawn_graph(%Graph{
               name: :my_graph,
               starting_node: :red,
               nodes: [
                 %Node{
                   name: :red,
                   exits_to: [:yellow],
                   timer: %Timer{duration: 30000, exits_to: :yellow}
                 },
                 %Node{
                   name: :yellow,
                   exits_to: [:green],
                   timer: %Timer{duration: 10000, exits_to: :green}
                 },
                 %Node{
                   name: :green,
                   exits_to: [:red],
                   timer: %Timer{duration: 1000, exits_to: :red}
                 }
               ]
             })
  end
end

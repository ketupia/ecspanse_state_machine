defmodule EcspanseStateMachine.Internal.GraphFlattener do
  @moduledoc """
  Traverses a graph's nodes and flattens their visit order in a depth first approach

  This assumes the graph is valid
  """
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Components

  @spec flatten(Ecspanse.Entity.t()) :: list(binary()) | {:error, :not_found}
  def flatten(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      nodes_by_name =
        Locator.get_nodes(graph_entity)
        |> Enum.into(%{}, &{&1.name, &1})

      data = %{
        visited: [],
        nodes_by_name: nodes_by_name
      }

      data = traverse(graph_component.starting_node_name, data)
      Enum.reverse(data.visited)
    end
  end

  def traverse(node_name, data) do
    if Enum.member?(data.visited, node_name) do
      data
    else
      data = Map.put(data, :visited, List.insert_at(data.visited, 0, node_name))
      node = Map.get(data.nodes_by_name, node_name)

      Enum.reduce(node.allowed_exit_node_names, data, fn exit_node_name, acc ->
        traverse(exit_node_name, acc)
      end)
    end
  end
end

defmodule EcspanseStateMachine.Internal.Locator do
  @moduledoc """
  Functions to find graphs and nodes by name or reference
  """
  alias EcspanseStateMachine.Internal.Components

  @spec fetch_graph_entity_for_node(Ecspanse.Entity.t()) ::
          {:ok, Ecspanse.Entity.t()} | {:error, :not_found}
  @doc """
  Fetches the graph entity for a node
  """
  def fetch_graph_entity_for_node(node_entity) do
    graph_component =
      Ecspanse.Query.list_tagged_components_for_parents(node_entity, [
        :ecspanse_state_machine_graph
      ])
      |> List.first()

    case graph_component do
      nil -> {:error, :not_found}
      graph_component -> {:ok, Ecspanse.Query.get_component_entity(graph_component)}
    end
  end

  @spec fetch_node_component_by_name(Ecspanse.Entity.t(), atom()) ::
          {:ok, Components.Node.t()} | {:error, :not_found}
  @doc """
  Fetches the node component in the graph by name
  """
  def fetch_node_component_by_name(graph_entity, node_name) do
    case get_node_component_by_name(graph_entity, node_name) do
      nil -> {:error, :not_found}
      node_component -> {:ok, node_component}
    end
  end

  def get_node_component_by_name(graph_entity, node_name) do
    get_nodes(graph_entity)
    |> Enum.find(&(&1.name == node_name))
  end

  @spec get_nodes(Ecspanse.Entity.t()) :: list(Components.Node.t())
  def get_nodes(graph_entity) do
    Ecspanse.Query.list_tagged_components_for_children(graph_entity, [
      :ecspanse_state_machine_node
    ])
  end
end

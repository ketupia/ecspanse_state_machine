defmodule EcspanseStateMachine.Internals.Locator do
  @moduledoc """
  Functions to find graphs and nodes by name or reference
  """
  alias EcspanseStateMachine.Components

  @spec fetch_graph_component_by_name(atom()) ::
          {:ok, Components.Graph.t()} | {:error, :not_found}
  @doc """
  Fetches the graph component by name in a `with` friendly way
  """
  def fetch_graph_component_by_name(graph_name) do
    case get_graph_component_by_name(graph_name) do
      nil -> {:error, :not_found}
      graph_component -> {:ok, graph_component}
    end
  end

  @spec fetch_graph_component_for_node(Components.Node.t()) ::
          {:ok, Components.Graph.t()} | {:error, :not_found}
  @doc """
  Fetches the graph component for a node in a `with` friendly way
  """
  def fetch_graph_component_for_node(node_component) do
    case get_graph_component_for_node(node_component) do
      nil -> {:error, :not_found}
      graph_component -> {:ok, graph_component}
    end
  end

  @spec get_graph_component_by_name(atom()) :: Components.Graph.t() | nil
  def get_graph_component_by_name(graph_name) when is_atom(graph_name) do
    Ecspanse.Query.list_tagged_components([:ecspanse_state_machine_graph])
    |> Enum.find(fn graph -> graph.name == graph_name end)
  end

  @spec get_graph_component_for_node(Components.Node.t()) :: Components.Graph.t() | nil
  def get_graph_component_for_node(node_component) do
    node_entity = Ecspanse.Query.get_component_entity(node_component)

    Ecspanse.Query.list_tagged_components_for_parents(node_entity, [
      :ecspanse_state_machine_graph
    ])
    |> List.first()
  end

  @spec fetch_node_component(Components.Graph.t(), atom()) ::
          {:ok, Components.Node.t()} | {:error, :not_found}
  @doc """
  Fetches the node component in the graph by name in a `with` friendly way
  """
  def fetch_node_component(graph_component, node_name) do
    case get_node_component(graph_component, node_name) do
      nil -> {:error, :not_found}
      node_component -> {:ok, node_component}
    end
  end

  @spec get_node_component(Components.Graph.t(), atom()) :: Components.Node.t() | nil
  def get_node_component(graph_component, node_name) do
    get_nodes(graph_component)
    |> Enum.find(&(&1.name == node_name))
  end

  @spec fetch_nodes(atom()) :: {:ok, list(Components.Node.t())} | {:error, :not_found}
  @doc """
  Retrieves the list of nodes for the graph
  """
  def fetch_nodes(graph_name) do
    with {:ok, graph_component} <- fetch_graph_component_by_name(graph_name) do
      {:ok, get_nodes(graph_component)}
    end
  end

  @spec get_nodes(Components.Graph.t()) :: list(Components.Node.t())
  def get_nodes(graph_component) do
    graph_entity = Ecspanse.Query.get_component_entity(graph_component)

    Ecspanse.Query.list_tagged_components_for_children(graph_entity, [
      :ecspanse_state_machine_node
    ])
  end
end

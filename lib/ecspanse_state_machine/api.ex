defmodule EcspanseStateMachine.Api do
  @moduledoc """
  Functions to assist reading the state of the machine
  """
  alias EcspanseStateMachine.Mermaid
  alias EcspanseStateMachine.Events
  alias EcspanseStateMachine.Projections
  alias EcspanseStateMachine.Internals.Locator

  @spec as_mermaid_diagram(Ecspanse.Entity.id()) :: {:ok, String.t()} | {:error, :not_found}
  def as_mermaid_diagram(entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, graph_component} <- EcspanseStateMachine.Components.Graph.fetch(graph_entity) do
      nodes = Locator.get_nodes(graph_component)

      [
        Mermaid.to_state_diagram(graph_component),
        Enum.map_join(nodes, "\n", &Mermaid.to_state_diagram(&1))
      ]
      |> Enum.join("\n")
    end
  end

  @spec fetch_graph(atom() | Ecspanse.Entity.id()) ::
          {:ok, Projections.Graph.t()} | {:error, :not_found}
  @doc """
  Retrieves a graph by name or entity_id
  """
  def fetch_graph(graph_name) when is_atom(graph_name) do
    case Locator.fetch_graph_component_by_name(graph_name) do
      {:ok, graph_component} ->
        graph_entity = Ecspanse.Query.get_component_entity(graph_component)
        Projections.Graph.project(%{entity_id: graph_entity.id})

      error ->
        error
    end
  end

  def fetch_graph(graph_entity_id) do
    Projections.Graph.project(%{entity_id: graph_entity_id})
  end

  @spec fetch_node(atom(), atom()) :: {:ok, Projections.Graph.t()} | {:error, :not_found}
  @doc """
  Retrieves the node in a graph
  """
  def fetch_node(graph_name, node_name) do
    with {:ok, graph_component} <- Locator.fetch_graph_component_by_name(graph_name),
         {:ok, node_component} <- Locator.fetch_node_component(graph_component, node_name) do
      node_entity = Ecspanse.Query.get_component_entity(node_component)
      Projections.Node.project(%{entity_id: node_entity.id})
    end
  end

  @spec submit_start_graph_request(atom()) :: :ok | {:error, :not_found}
  @doc """
  Submits a start graph request if the graph exists
  """
  def submit_start_graph_request(graph_name) do
    case Locator.fetch_graph_component_by_name(graph_name) do
      {:ok, graph_component} ->
        Ecspanse.event({Events.StartGraphRequest, [graph_name: graph_component.name]})

      error ->
        error
    end
  end

  @spec submit_node_transition_request(atom(), atom()) :: :ok | {:error, :not_found}
  @doc """
  Submits a request to transition to the target node name
  """
  def submit_node_transition_request(graph_name, target_node_name) do
    case Locator.fetch_graph_component_by_name(graph_name) do
      {:ok, graph_component} ->
        Ecspanse.event(
          {Events.NodeTransitionRequest,
           [graph_name: graph_component.name, target_node_name: target_node_name]}
        )

      error ->
        error
    end
  end
end

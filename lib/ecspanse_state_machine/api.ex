defmodule EcspanseStateMachine.Api do
  @moduledoc """
  Functions to assist reading the state of the machine
  """
  alias EcspanseStateMachine.Internal.Components
  alias EcspanseStateMachine.Internal.Mermaid
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Projections
  alias EcspanseStateMachine.Internal.Locator

  @spec as_mermaid_diagram(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          {:ok, String.t()} | {:error, :not_found}
  @doc """
  Generates the source for a Mermaid State Diagram
  """
  def as_mermaid_diagram(graph_entity_id) when is_binary(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      as_mermaid_diagram(graph_entity)
    end
  end

  def as_mermaid_diagram(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      nodes = Locator.get_nodes(graph_component)

      [
        Mermaid.to_state_diagram(graph_component),
        Enum.map_join(nodes, "\n", &Mermaid.to_state_diagram(&1))
      ]
      |> Enum.join("\n")
    end
  end

  @spec submit_node_transition_request(
          Ecspanse.Entity.id() | Ecspanse.Entity.t(),
          atom(),
          atom(),
          atom()
        ) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to transition to the target node name
  """
  def submit_node_transition_request(
        graph_entity_reference,
        current_node_name,
        target_node_name,
        reason \\ :request
      )

  def submit_node_transition_request(
        graph_entity_id,
        current_node_name,
        target_node_name,
        reason
      )
      when is_binary(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      submit_node_transition_request(graph_entity, current_node_name, target_node_name, reason)
    end
  end

  def submit_node_transition_request(
        graph_entity,
        current_node_name,
        target_node_name,
        reason
      ) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      Ecspanse.event(
        {Events.NodeTransitionRequest,
         [
           graph_name: graph_component.name,
           current_node_name: current_node_name,
           target_node_name: target_node_name,
           reason: reason
         ]}
      )
    end
  end

  @spec submit_start_graph_request(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to start the graph running
  """
  def submit_start_graph_request(graph_entity_id) when is_binary(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      submit_start_graph_request(graph_entity)
    end
  end

  def submit_start_graph_request(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      Ecspanse.event({Events.StartGraphRequest, [graph_name: graph_component.name]})
    end
  end

  @spec submit_stop_graph_request(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to stop the graph running
  """
  def submit_stop_graph_request(graph_entity_id) when is_binary(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      submit_stop_graph_request(graph_entity)
    end
  end

  def submit_stop_graph_request(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      Ecspanse.event({Events.StopGraphRequest, [graph_name: graph_component.name]})
    end
  end

  @spec project(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          {:ok, Projections.Graph.t()} | {:error, :not_found}
  @doc """
  Retrieves the projection of the graph
  """
  def project(graph_entity_id) when is_binary(graph_entity_id) do
    Projections.Graph.project(%{entity_id: graph_entity_id})
  end

  def project(graph_entity) do
    project(graph_entity.id)
  end
end

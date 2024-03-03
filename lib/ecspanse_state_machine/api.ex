defmodule EcspanseStateMachine.Api do
  @moduledoc """
  Functions to assist reading the state of the machine
  """
  alias EcspanseStateMachine.Internal.GraphValidator
  alias EcspanseStateMachine.Internal.Mermaid
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Projections

  @spec as_mermaid_diagram(Ecspanse.Entity.id()) ::
          {:ok, String.t()} | {:error, :not_found}
  @doc """
  Generates the source for a Mermaid State Diagram
  """
  def as_mermaid_diagram(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      Mermaid.as_state_diagram(graph_entity)
    end
  end

  @spec submit_node_transition_request(Ecspanse.Entity.id(), atom(), atom(), atom()) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to transition to the target node name
  """
  def submit_node_transition_request(
        graph_entity_id,
        from_node_name,
        to_node_name,
        reason \\ :request
      ) do
    Ecspanse.event(
      {Events.NodeTransitionRequest,
       [
         graph_entity_id: graph_entity_id,
         from_node_name: from_node_name,
         to_node_name: to_node_name,
         reason: reason
       ]}
    )
  end

  @spec submit_start_graph_request(Ecspanse.Entity.id()) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to start the graph running
  """
  def submit_start_graph_request(graph_entity_id) do
    Ecspanse.event({Events.StartGraphRequest, [entity_id: graph_entity_id]})
  end

  @spec submit_stop_graph_request(Ecspanse.Entity.id()) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to stop the graph running
  """
  def submit_stop_graph_request(graph_entity_id) do
    Ecspanse.event({Events.StopGraphRequest, [entity_id: graph_entity_id]})
  end

  @spec project(Ecspanse.Entity.id()) ::
          {:ok, Projections.Graph.t()} | {:error, :not_found}
  @doc """
  Retrieves the projection of the graph
  """
  def project(graph_entity_id) do
    Projections.Graph.project(%{entity_id: graph_entity_id})
  end

  @spec validate_graph(Ecspanse.Entity.id()) ::
          :ok | {:error, :not_found} | {:error, String.t()}
  def validate_graph(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      GraphValidator.validate(graph_entity)
    end
  end
end

defmodule EcspanseStateMachine.Internal.Systems.OnNodeTransitionRequest do
  @moduledoc """
  transitions from the current node to the target node when a transition request event is received
  """

  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Internal.Events

  use Ecspanse.System,
    event_subscriptions: [Events.NodeTransitionRequest]

  def run(
        %Events.NodeTransitionRequest{
          graph_entity_id: graph_entity_id,
          current_node_name: current_node_name,
          target_node_name: target_node_name,
          reason: reason
        },
        _frame
      ) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id),
         {:ok, current_node_component} <-
           Locator.fetch_node_component_by_name(graph_entity, current_node_name),
         {:ok, target_node_component} <-
           Locator.fetch_node_component_by_name(graph_entity, target_node_name) do
      Engine.maybe_transition_nodes(
        graph_entity,
        current_node_component,
        target_node_component,
        reason
      )
    end
  end
end

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
          from_node_name: from_node_name,
          to_node_name: to_node_name,
          reason: reason
        },
        _frame
      ) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id),
         {:ok, from_node_component} <-
           Locator.fetch_node_component_by_name(graph_entity, from_node_name),
         {:ok, to_node_name} <-
           Locator.fetch_node_component_by_name(graph_entity, to_node_name) do
      Engine.maybe_transition_nodes(
        graph_entity,
        from_node_component,
        to_node_name,
        reason
      )
    end
  end
end

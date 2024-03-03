defmodule EcspanseStateMachine.Internal.Systems.OnNodeTimeout do
  @moduledoc """
  Triggers a transition from the current node to the timeout node when a timeout timer elapses
  """

  alias EcspanseStateMachine.Internal.Components
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Internal.Locator

  use Ecspanse.System,
    event_subscriptions: [Events.NodeTimeout]

  def run(%Events.NodeTimeout{entity_id: entity_id}, _frame) do
    with {:ok, node_entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, node_component} <- Components.Node.fetch(node_entity),
         {:ok, graph_entity} <- Locator.fetch_graph_entity_for_node(node_entity),
         {:ok, timeout_node_component} <-
           Locator.fetch_node_component_by_name(graph_entity, node_component.timeout_node_name) do
      Engine.maybe_transition_nodes(
        graph_entity,
        node_component,
        timeout_node_component,
        :timeout
      )
    end
  end
end

defmodule EcspanseStateMachine.Systems.OnNodeTimeout do
  @moduledoc """
  Triggers a transition from the current node to the timeout node when a timeout timer elapses
  """

  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Events
  alias EcspanseStateMachine.Internals.Engine
  alias EcspanseStateMachine.Internals.Locator

  use Ecspanse.System,
    event_subscriptions: [Events.NodeTimeout]

  def run(%Events.NodeTimeout{entity_id: entity_id}, _frame) do
    with {:ok, node_entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, node_component} <- Components.Node.fetch(node_entity),
         {:ok, graph_component} <- Locator.fetch_graph_component_for_node(node_component),
         {:ok, timeout_node_component} <-
           Locator.fetch_node_component(graph_component, node_component.timeout_node_name) do
      Engine.maybe_transition_nodes(
        graph_component,
        node_component,
        timeout_node_component,
        :timeout
      )
    end
  end
end

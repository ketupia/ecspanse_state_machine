defmodule EcspanseStateMachine.Systems.OnNodeTransitionRequest do
  @moduledoc """
  transitions from the current node to the target node when a transition request event is received
  """

  alias EcspanseStateMachine.Internals.Locator
  alias EcspanseStateMachine.Internals.Engine
  alias EcspanseStateMachine.Events

  use Ecspanse.System,
    event_subscriptions: [Events.NodeTransitionRequest]

  def run(
        %Events.NodeTransitionRequest{graph_name: graph_name, target_node_name: target_node_name},
        _frame
      ) do
    with {:ok, graph_component} <- Locator.fetch_graph_component_by_name(graph_name),
         {:ok, node_component} <- Locator.fetch_node_component(graph_component, target_node_name) do
      Engine.maybe_transition_nodes(graph_component, node_component, :request)
    end
  end
end

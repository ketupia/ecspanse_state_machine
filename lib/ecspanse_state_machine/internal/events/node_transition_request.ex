defmodule EcspanseStateMachine.Internal.Events.NodeTransitionRequest do
  @moduledoc """
  Requests a node transition

  This will trigger a node transition so long as
  * the graph is running
  * the from_node is the graph's current node
  * the target node is valid from the current node

  ## Fields
  * graph_entity_id: the entity_id of the graph
  * from_node_name: the name of the node to transition from
  * to_node_name: the target node name to transition to
  * reason: an optional field to assist in tracking why a transition occurred.  Default: :request
  """
  use Ecspanse.Event, fields: [:graph_entity_id, :from_node_name, :to_node_name, :reason]
end

defmodule EcspanseStateMachine.Internal.Events.NodeTransitionRequest do
  @moduledoc """
  Requests a node transition

  This will trigger a node transition so long as
  * the graph is running
  * the current_node is still the graph's current node
  * the target node is valid from the current node

  ## Fields
  * graph_name: the name of the graph to start
  * current_node_name: the name of the current node
  * target_node_name: the target node name to transition to
  * reason: an optional field to assist in tracking why a transition occurred.  Default: :request
  """
  use Ecspanse.Event, fields: [:graph_name, :current_node_name, :target_node_name, :reason]
end

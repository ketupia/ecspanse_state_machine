defmodule EcspanseStateMachine.Events.NodeTransitionRequest do
  @moduledoc """
  Requests a node transition

  This will trigger a node transition so long as
  * the graph is running
  * the node exists
  * the target node is valid from the current node

  ## Fields
  * graph_name: the name of the graph to start
  * target_node_name: the target node name to transition to
  """
  use Ecspanse.Event, fields: [:graph_name, :graph_reference, :target_node_name]
end

defmodule EcspanseStateMachine.Events.NodeTransition do
  @moduledoc """
  Emitted when moving from one node to another

  ## Fields
  * graph_name: the name of the graph
  * previous_node_name: the previous node name
  * current_node_name: the current node name
  * reason: the reason for the transition (e.g. :timeout, :graph_start, :requested)
  """
  use Ecspanse.Event,
    fields: [:graph_name, :graph_reference, :previous_node_name, :current_node_name, :reason]
end

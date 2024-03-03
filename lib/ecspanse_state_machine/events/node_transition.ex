defmodule EcspanseStateMachine.Events.NodeTransition do
  @moduledoc """
  Emitted when moving from one node to another

  ## Fields
  * graph_entity_id: the ECSpanse entity id of the graph
  * graph_name: the name of the graph
  * from_node_name: the previous node name
  * to_node_name: the current node name
  * reason: the reason for the transition (e.g. :timeout, :graph_start, :requested)
  """
  use Ecspanse.Event,
    fields: [
      :graph_entity_id,
      :graph_name,
      :graph_metadata,
      :from_node_name,
      :to_node_name,
      :reason
    ]
end

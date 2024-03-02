defmodule EcspanseStateMachine.Events.GraphStarted do
  @moduledoc """
  Emitted When a graph starts

  ## Fields
  * graph_entity_id: the ECSpanse entity id of the graph
  * graph_name: the name of the graph that started
  * graph_reference: the reference provided when the graph was started
  """
  use Ecspanse.Event, fields: [:graph_entity_id, :graph_name, :graph_reference]
end

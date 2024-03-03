defmodule EcspanseStateMachine.Internal.Events.StartGraphRequest do
  @moduledoc """
  Emitted to start a graph processing.
  When the graph starts, a transition into the start_node
  will be emitted and that state's timer will be started if it has one.

  ## Fields
  * entity_id: the entity id of the graph to start
  """
  use Ecspanse.Event, fields: [:entity_id]
end

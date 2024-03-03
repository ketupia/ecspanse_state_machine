defmodule EcspanseStateMachine.Internal.Events.StopGraphRequest do
  @moduledoc """
  Emitted to stop a running graph.
  The current node's timer will be stopped (if it has one).

  ## Fields
  * entity_id: the entity id of the graph to stop
  """
  use Ecspanse.Event, fields: [:entity_id]
end

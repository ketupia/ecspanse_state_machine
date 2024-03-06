defmodule EcspanseStateMachine.Internal.Events.StopRequest do
  @moduledoc """
  Emitted to stop a machine.

  ## Fields
  * entity_id: the entity id of the state machine to stop
  """
  use Ecspanse.Event, fields: [:entity_id]
end

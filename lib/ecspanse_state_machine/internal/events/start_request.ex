defmodule EcspanseStateMachine.Internal.Events.StartRequest do
  @moduledoc """
  Emitted to start a state machine.
  When the machine starts, the state will change to the initial state

  ## Fields
  * entity_id: the entity id of the state machine to start
  """
  use Ecspanse.Event, fields: [:entity_id]
end

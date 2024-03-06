defmodule EcspanseStateMachine.Events.Stopped do
  @moduledoc """
  Emitted When a state machine is stopped

  ## Fields
  * entity_id: the id of the entity containing the state machine
  """
  use Ecspanse.Event, fields: [:entity_id]
end

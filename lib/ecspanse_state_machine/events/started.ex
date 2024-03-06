defmodule EcspanseStateMachine.Events.Started do
  @moduledoc """
  Emitted When a state machine starts

  ## Fields
  * entity_id: the id of the entity with the state machine
  """
  use Ecspanse.Event, fields: [:entity_id]
end

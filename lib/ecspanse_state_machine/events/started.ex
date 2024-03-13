defmodule EcspanseStateMachine.Events.Started do
  @moduledoc """
  Emitted when a state machine starts

  ## Fields
  * entity_id: the id of the entity with the state machine

  ## Examples
      %Started{entity_id: "78d51554-83c6-4c66-b043-a5bd71a2f2ce"}
  """
  use Ecspanse.Event, fields: [:entity_id]
end

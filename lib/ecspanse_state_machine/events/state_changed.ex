defmodule EcspanseStateMachine.Events.StateChanged do
  @moduledoc """
  Emitted when the state has changed

  ## Fields
  * entity_id: the id of the entity with the state machine
  * from: the previous state
  * to: the current state
  * trigger: the trigger for the transition (e.g. :timeout, :startup, :requested)

  ## Examples
      %StateChanged{entity_id: "78d51554-83c6-4c66-b043-a5bd71a2f2ce",
        from: "Battle Start",
        to: "Turn Start",
        trigger: :timeout}
  """
  use Ecspanse.Event,
    fields: [
      :entity_id,
      :from,
      :to,
      :trigger
    ]
end

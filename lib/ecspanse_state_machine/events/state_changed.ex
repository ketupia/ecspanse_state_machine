defmodule EcspanseStateMachine.Events.StateChanged do
  @moduledoc """
  Emitted when the state has changed

  ## Fields
  * entity_id: the id of the entity containing the state machine
  * from: the previous state
  * to: the current state
  * trigger: the trigger for the transition (e.g. :timeout, :startup, :requested)
  """
  use Ecspanse.Event,
    fields: [
      :entity_id,
      :from,
      :to,
      :trigger
    ]
end

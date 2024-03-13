defmodule EcspanseStateMachine.Internal.Events.StartRequest do
  @moduledoc false
  # Emitted to start a state machine.
  # When the machine starts, the state will change to the initial state

  use Ecspanse.Event, fields: [:entity_id]
end

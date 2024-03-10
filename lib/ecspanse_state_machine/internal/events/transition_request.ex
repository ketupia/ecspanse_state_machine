defmodule EcspanseStateMachine.Internal.Events.TransitionRequest do
  @moduledoc """
  Requests a change of states

  This will trigger a state change so long as
  * the state machine is running
  * the from_state is the machines's current state
  * the to_state is valid from the current state

  ## Fields
  * entity_id: the id of the entity containing the state machine
  * from: the name of the state to transition from
  * to: the name of the state to transition to
  * trigger: an optional field to assist in tracking why the change occurred.  Default: :request
  """
  use Ecspanse.Event, fields: [:entity_id, :from, :to, :trigger]
end

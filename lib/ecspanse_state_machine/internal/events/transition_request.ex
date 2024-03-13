defmodule EcspanseStateMachine.Internal.Events.TransitionRequest do
  @moduledoc false
  # Requests a change of states

  use Ecspanse.Event, fields: [:entity_id, :from, :to, :trigger]
end

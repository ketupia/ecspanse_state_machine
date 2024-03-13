defmodule EcspanseStateMachine.Internal.Events.StateTimeout do
  @moduledoc false
  # This event is triggered when a Timeout Timer elapses.

  use Ecspanse.Template.Event.Timer
end

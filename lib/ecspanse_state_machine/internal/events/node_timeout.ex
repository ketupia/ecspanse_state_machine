defmodule EcspanseStateMachine.Internal.Events.NodeTimeout do
  @moduledoc """
  This event is triggered when a Timeout Timer elapses.
  """
  use Ecspanse.Template.Event.Timer
end

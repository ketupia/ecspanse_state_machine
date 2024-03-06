defmodule EcspanseStateMachine.Internal.Systems.OnStopped do
  @moduledoc """
  Stops the Timeout Timer on state machine stop
  """
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Events
  require Logger

  use Ecspanse.System, event_subscriptions: [Events.Stopped]

  def run(%Events.Stopped{entity_id: entity_id}, _frame) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, timer} <- Components.StateTimer.fetch(entity) do
      Ecspanse.Command.update_component!(timer, paused: true, timing_state: nil)
    else
      _ ->
        :ok
    end
  end
end

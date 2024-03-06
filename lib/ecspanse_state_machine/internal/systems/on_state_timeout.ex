defmodule EcspanseStateMachine.Internal.Systems.OnStateTimeout do
  @moduledoc """
  Triggers a state change from the current state to the timeout exits_to state
  """

  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Components

  require Logger

  use Ecspanse.System,
    event_subscriptions: [Events.StateTimeout]

  def run(%Events.StateTimeout{entity_id: entity_id}, _frame) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, timer} <- Components.StateTimer.fetch(entity) do
      timeout = Components.StateTimer.get_timeout(timer, timer.timing_state)

      EcspanseStateMachine.change_state(
        entity_id,
        timer.timing_state,
        timeout[:exits_to],
        :timeout
      )
    else
      {:error, reason} ->
        Logger.warning(reason)
    end
  end
end

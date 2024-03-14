defmodule EcspanseStateMachine.Internal.Systems.OnStateTimeout do
  @moduledoc false
  # Triggers a state change from the current state to the timeout exit state

  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Components

  require Logger

  use Ecspanse.System,
    event_subscriptions: [Events.StateTimeout]

  def run(%Events.StateTimeout{entity_id: entity_id}, _frame) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      Engine.transition_to_default_exit(state_machine, state_machine.timing_state, :timeout)
    else
      {:error, reason} ->
        Logger.warning(reason)
    end
  end
end

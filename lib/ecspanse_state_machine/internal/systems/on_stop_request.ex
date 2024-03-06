defmodule EcspanseStateMachine.Internal.Systems.OnStopRequest do
  @moduledoc """
  Stops the  machine if it's running
  """
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Internal.Events
  require Logger

  use Ecspanse.System, event_subscriptions: [Events.StopRequest]

  def run(%Events.StopRequest{entity_id: entity_id}, _frame) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      stop(state_machine)
    else
      {:error, :not_found} ->
        Logger.warning("StopRequest: State Machine not found on entity #{entity_id}")
    end
  end

  def stop(state_machine) do
    if state_machine.is_running do
      Ecspanse.Command.update_component!(state_machine,
        is_running: false
      )

      # Logger.info(
      #   "State Machine for #{Ecspanse.Query.get_component_entity(state_machine).id} in now stopped.  State: #{inspect(state_machine.current_state)}"
      # )

      entity = Ecspanse.Query.get_component_entity(state_machine)

      # Ecspanse.event(
      #   {StateMachine.Events.StateChanged,
      #    [entity_id: entity.id, from: state_machine.current_state, to: nil, trigger: :stopped]}
      # )

      Ecspanse.event({EcspanseStateMachine.Events.Stopped, [entity_id: entity.id]})
    else
      :ok
    end
  end
end

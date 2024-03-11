defmodule EcspanseStateMachine.Internal.Systems.OnStopRequest do
  @moduledoc """
  Stops the  machine if it's running
  """
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.Telemetry
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
      telemetry_start_time = state_machine.telemetry_start_time
      telemetry_state_start_time = state_machine.telemetry_state_start_time
      state = state_machine.current_state

      Ecspanse.Command.update_component!(state_machine,
        is_running: false,
        current_state: nil,
        telemetry_start_time: 0,
        telemetry_state_start_time: 0
      )

      entity = Ecspanse.Query.get_component_entity(state_machine)

      Ecspanse.event({EcspanseStateMachine.Events.Stopped, [entity_id: entity.id]})

      Telemetry.stop(state_machine, telemetry_start_time)
      Telemetry.stop(state_machine, state, telemetry_state_start_time)
    else
      :ok
    end
  end
end

defmodule EcspanseStateMachine.Internal.Systems.OnStartRequest do
  @moduledoc false
  # Starts the machine unless it is already running

  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.Telemetry
  require Logger

  use Ecspanse.System, event_subscriptions: [Events.StartRequest]

  def run(%Events.StartRequest{entity_id: entity_id}, _frame) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      start(state_machine)
    else
      {:error, :not_found} ->
        Logger.warning("StartRequest: State Machine not found on entity #{entity_id}")
    end
  end

  defp start(state_machine) do
    if state_machine.is_running do
      :ok
    else
      telemetry_start_time = Telemetry.time()

      Ecspanse.Command.update_component!(state_machine,
        current_state: state_machine.initial_state,
        is_running: true,
        telemetry_start_time: telemetry_start_time,
        telemetry_state_start_time: telemetry_start_time
      )

      Telemetry.start(state_machine, telemetry_start_time)
      Telemetry.start(state_machine, state_machine.initial_state, telemetry_start_time)

      entity = Ecspanse.Query.get_component_entity(state_machine)
      Ecspanse.event({EcspanseStateMachine.Events.Started, [entity_id: entity.id]})

      Ecspanse.event(
        {EcspanseStateMachine.Events.StateChanged,
         [entity_id: entity.id, from: nil, to: state_machine.initial_state, trigger: :startup]}
      )
    end
  end
end

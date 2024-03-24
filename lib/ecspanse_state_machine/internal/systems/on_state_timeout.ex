defmodule EcspanseStateMachine.Internal.Systems.OnStateTimeout do
  @moduledoc false
  # Triggers a state change from the current state to the timeout exit state

  alias EcspanseStateMachine.Internal
  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.StateSpec
  alias EcspanseStateMachine.Components

  require Logger

  use Ecspanse.System,
    event_subscriptions: [Events.StateTimeout]

  def run(%Events.StateTimeout{entity_id: entity_id}, _frame) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id),
         :ok <- ensure_current_state_is_not_nil(state_machine),
         :ok <- ensure_current_state_has_timeout(state_machine),
         :ok <- ensure_delta_time_meets_timeout(state_machine) do
      Engine.transition_to_default_exit(state_machine, state_machine.current_state, :timeout)
    end
  end

  defp ensure_current_state_is_not_nil(state_machine) do
    case state_machine.current_state do
      nil -> {:error, "Current state is nil"}
      _ -> :ok
    end
  end

  defp ensure_current_state_has_timeout(state_machine) do
    state_spec =
      Components.StateMachine.get_state_spec(state_machine, state_machine.current_state)

    case StateSpec.has_timeout?(state_spec) do
      true -> :ok
      false -> {:error, "#{inspect(state_machine.current_state)} does not have a timeout"}
    end
  end

  defp ensure_delta_time_meets_timeout(state_machine) do
    state_spec =
      Components.StateMachine.get_state_spec(state_machine, state_machine.current_state)

    elapsed_milliseconds =
      System.convert_time_unit(
        System.monotonic_time() - state_machine.telemetry_state_start_time,
        :native,
        :millisecond
      )

    case elapsed_milliseconds >= StateSpec.timeout(state_spec) do
      false ->
        {:error,
         "Insufficient time has elapsed for #{inspect(state_machine.current_state)} for a valid timeout"}

      _ ->
        :ok
    end
  end
end

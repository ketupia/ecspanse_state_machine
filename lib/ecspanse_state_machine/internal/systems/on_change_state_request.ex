defmodule EcspanseStateMachine.Internal.Systems.OnChangeStateRequest do
  @moduledoc """
    transitions from the current state to the exit state
  """
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Components
  require Logger

  use Ecspanse.System,
    event_subscriptions: [Events.ChangeStateRequest]

  def run(
        %Events.ChangeStateRequest{
          entity_id: entity_id,
          from: from,
          to: to,
          trigger: trigger
        },
        _frame
      ) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      change_state(state_machine, from, to, trigger)
    else
      {:error, :not_found} ->
        Logger.warning("ChangeStateRequest: State Machine not found on entity #{entity_id}")
    end
  end

  defp change_state(state_machine, from, to, trigger) do
    with :ok <- ensure_is_running(state_machine),
         :ok <- ensure_from_matches_current_state(state_machine, from),
         :ok <- ensure_is_allowed_exit(state_machine, to) do
      Ecspanse.Command.update_component!(state_machine, current_state: to)

      # Logger.info(
      #   "State for #{Ecspanse.Query.get_component_entity(state_machine).id} in now: #{inspect(to)}"
      # )

      entity = Ecspanse.Query.get_component_entity(state_machine)

      Ecspanse.event(
        {EcspanseStateMachine.Events.StateChanged,
         [entity_id: entity.id, from: from, to: to, trigger: trigger]}
      )

      state = Components.StateMachine.get_state(state_machine, to)

      if Enum.empty?(state[:exits_to]) do
        EcspanseStateMachine.stop(entity.id)
      end
    else
      error = {:error, reason} ->
        Logger.warning(
          "Could not change states from #{inspect(from)} to #{inspect(to)} trigger #{inspect(trigger)} for #{Ecspanse.Query.get_component_entity(state_machine).id}: #{reason}"
        )

        error
    end
  end

  @spec ensure_is_allowed_exit(Components.StateMachine.t(), atom()) :: :ok | {:error, String.t()}
  defp ensure_is_allowed_exit(state_machine, to) do
    state = Components.StateMachine.get_state(state_machine, state_machine.current_state)

    if to in state[:exits_to] do
      :ok
    else
      {:error,
       "To, #{inspect(to)}, is not an exit from the current state, #{state_machine.current_state}"}
    end
  end

  @spec ensure_from_matches_current_state(Components.StateMachine.t(), atom()) ::
          :ok | {:error, String.t()}
  defp ensure_from_matches_current_state(state_machine, from) do
    if state_machine.current_state == from do
      :ok
    else
      {:error,
       "From, #{inspect(from)}, does not match the current state #{state_machine.current_state}"}
    end
  end

  @spec ensure_is_running(Components.StateMachine.t()) :: :ok | {:error, String.t()}
  defp ensure_is_running(state_machine) do
    if state_machine.is_running do
      :ok
    else
      {:error, "State machine not running"}
    end
  end
end

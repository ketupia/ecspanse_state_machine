defmodule EcspanseStateMachine.Internal.Engine do
  @moduledoc false

  # Procedures to operate state machines

  alias EcspanseStateMachine.Components.StateMachine
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Events
  alias EcspanseStateMachine.Internal.StateSpec
  alias EcspanseStateMachine.Internal.Telemetry
  use EcspanseStateMachine.Types

  @doc """
  Retrieves the current state of the state machine in the given entity so long as it is running.
  """
  @spec current_state(StateMachine.t()) :: {:ok, state_name()} | {:error, :not_running}
  def current_state(%StateMachine{} = state_machine) do
    with :ok <- ensure_is_running(state_machine) do
      {:ok, state_machine.current_state}
    end
  end

  @spec ensure_from_matches_current_state(any(), state_name()) :: :ok | {:error, String.t()}
  defp ensure_from_matches_current_state(state_machine, from) do
    case state_machine.current_state == from do
      true ->
        :ok

      false ->
        {:error,
         "From, #{inspect(from)}, does not match the current state #{state_machine.current_state}"}
    end
  end

  @spec ensure_is_allowed_exit(any(), state_name()) :: :ok | {:error, String.t()}
  defp ensure_is_allowed_exit(%Components.StateMachine{} = state_machine, to) do
    current_state_spec =
      Components.StateMachine.get_state_spec(state_machine, state_machine.current_state)

    case StateSpec.has_exit?(current_state_spec, to) do
      true ->
        :ok

      _ ->
        {:error,
         "To, #{inspect(to)}, is not an exit from the current state, #{state_machine.current_state}"}
    end
  end

  @spec ensure_is_running(any()) :: :ok | {:error, :not_running}
  defp ensure_is_running(state_machine) do
    if state_machine.running? do
      :ok
    else
      {:error, :not_running}
    end
  end

  @spec ensure_is_not_running(any()) :: :ok | {:error, :already_running}
  defp ensure_is_not_running(state_machine) do
    if state_machine.running? do
      {:error, :already_running}
    else
      :ok
    end
  end

  @spec start(any()) :: :ok | {:error, :already_running}
  def start(%Components.StateMachine{} = state_machine) do
    with :ok <- ensure_is_not_running(state_machine) do
      telemetry_start_time = Telemetry.time()

      changes = [
        auto_start: false,
        current_state: state_machine.initial_state,
        running?: true,
        telemetry_start_time: telemetry_start_time,
        telemetry_state_start_time: telemetry_start_time
      ]

      timeout_duration =
        Components.StateMachine.get_state_spec(state_machine, state_machine.initial_state)
        |> StateSpec.timeout()

      changes =
        case timeout_duration do
          nil ->
            changes

          timeout_duration ->
            changes
            |> Keyword.put(:paused, false)
            |> Keyword.put(:duration, timeout_duration)
            |> Keyword.put(:time, timeout_duration)
        end

      Ecspanse.Command.update_component!(state_machine, changes)

      Telemetry.start(state_machine, telemetry_start_time)
      Telemetry.start(state_machine, state_machine.initial_state, telemetry_start_time)

      entity = Ecspanse.Query.get_component_entity(state_machine)
      Ecspanse.event({Events.Started, [entity_id: entity.id]})

      Ecspanse.event(
        {Events.StateChanged,
         [entity_id: entity.id, from: nil, to: state_machine.initial_state, trigger: :startup]}
      )
    end
  end

  @spec stop(any()) :: :ok | {:error, :not_running}
  def stop(%Components.StateMachine{} = state_machine) do
    with :ok <- ensure_is_running(state_machine) do
      telemetry_start_time = state_machine.telemetry_start_time
      telemetry_state_start_time = state_machine.telemetry_state_start_time
      state = state_machine.current_state

      Ecspanse.Command.update_component!(state_machine,
        running?: false,
        current_state: nil,
        telemetry_start_time: 0,
        telemetry_state_start_time: 0,
        paused: true
      )

      entity = Ecspanse.Query.get_component_entity(state_machine)

      Ecspanse.event({EcspanseStateMachine.Events.Stopped, [entity_id: entity.id]})

      Telemetry.stop(state_machine, state, telemetry_state_start_time)
      Telemetry.stop(state_machine, telemetry_start_time)
    end
  end

  @doc """
  Ensures the transition is valid and then changes the state, executes telemetry, and emits events.
  """
  @spec transition(any(), state_name(), state_name(), any()) ::
          :ok | {:error, :not_running} | {:error, String.t()}
  def transition(%Components.StateMachine{} = state_machine, from, to, trigger) do
    with :ok <- ensure_is_running(state_machine),
         :ok <- ensure_from_matches_current_state(state_machine, from),
         :ok <- ensure_is_allowed_exit(state_machine, to) do
      telemetry_entered_from_time = state_machine.telemetry_state_start_time
      telemetry_entered_to_time = Telemetry.time()

      changes = [
        paused: true,
        current_state: to,
        telemetry_state_start_time: telemetry_entered_to_time
      ]

      timeout_duration =
        Components.StateMachine.get_state_spec(state_machine, to)
        |> StateSpec.timeout()

      changes =
        case timeout_duration do
          nil ->
            changes

          timeout_duration ->
            changes
            |> Keyword.put(:paused, false)
            |> Keyword.put(:duration, timeout_duration)
            |> Keyword.put(:time, timeout_duration)
        end

      Ecspanse.Command.update_component!(state_machine, changes)

      Telemetry.stop(state_machine, from, telemetry_entered_from_time)

      Telemetry.start(state_machine, to, telemetry_entered_to_time)

      entity = Ecspanse.Query.get_component_entity(state_machine)

      Ecspanse.event(
        {Events.StateChanged, [entity_id: entity.id, from: from, to: to, trigger: trigger]}
      )

      exits =
        Components.StateMachine.get_state_spec(state_machine, to)
        |> StateSpec.exits()

      if Enum.empty?(exits) do
        stop(state_machine)
      end

      :ok
    end
  end

  @doc """
  Transitions to the timeout exit for the from state.  This is either the listed default_exit value or the first exit
  """
  @spec transition_to_default_exit(any(), state_name(), any()) ::
          :ok | {:error, :not_running} | {:error, String.t()}
  def transition_to_default_exit(%Components.StateMachine{} = state_machine, from, trigger) do
    with from_state_spec <- Components.StateMachine.get_state_spec(state_machine, from) do
      transition(state_machine, from, StateSpec.default_exit(from_state_spec), trigger)
    end
  end
end

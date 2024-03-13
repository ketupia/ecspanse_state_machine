defmodule EcspanseStateMachine.Internal.Telemetry do
  @moduledoc false
  # Executes Telemetry events for the State Machine

  alias EcspanseStateMachine.Projections
  alias EcspanseStateMachine.Components.StateMachine

  # @doc false
  # def exception(event, start_time, kind, reason, stack, meta \\ %{}, extra_measurements \\ %{}) do
  #   :telemetry.execute(
  #     [:ecspanse_state_machine, event, :exception],
  #     Map.merge(extra_measurements, %{duration: System.monotonic_time() - start_time}),
  #     meta
  #     |> Map.put(:kind, kind)
  #     |> Map.put(:error, reason)
  #     |> Map.put(:stacktrace, stack)
  #   )
  # end

  @doc false
  def start(%StateMachine{} = state_machine, start_time) do
    with {:ok, meta} <- Projections.StateMachine.project(state_machine) do
      :telemetry.execute(
        [:ecspanse_state_machine, :start],
        %{system_time: start_time},
        %{state_machine: meta}
      )
    end
  end

  def start(%StateMachine{} = state_machine, state, start_time) do
    with {:ok, meta} <- Projections.StateMachine.project(state_machine) do
      :telemetry.execute(
        [:ecspanse_state_machine, :state, :start],
        %{system_time: start_time},
        %{state_machine: meta, state: state}
      )
    end
  end

  @doc """
  Executes a stop for the state machine
  """
  def stop(%StateMachine{} = state_machine, start_time) do
    with {:ok, state_machine_meta} <- Projections.StateMachine.project(state_machine) do
      :telemetry.execute(
        [:ecspanse_state_machine, :stop],
        %{duration: System.monotonic_time() - start_time},
        %{state_machine: state_machine_meta}
      )
    end
  end

  @doc """
  Executes a stop for the given state.
  """
  def stop(%StateMachine{} = state_machine, state, start_time) do
    with {:ok, state_machine_meta} <- Projections.StateMachine.project(state_machine) do
      :telemetry.execute(
        [:ecspanse_state_machine, :state, :stop],
        %{duration: System.monotonic_time() - start_time},
        %{state_machine: state_machine_meta, state: state}
      )
    end
  end

  def time(), do: System.monotonic_time()
end

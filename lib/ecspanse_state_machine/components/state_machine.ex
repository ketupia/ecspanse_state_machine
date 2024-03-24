defmodule EcspanseStateMachine.Components.StateMachine do
  @moduledoc """
  The state machine component tracks the running status and current state.

  ## Fields
  * initial_state: the state the machine should be in at start
  * current_state: the state the machine is in now
  * states: keyword lists of states [:name, exits[:exit_state1, :exit_state2...], :timeout, :default_exit]
  * auto_start: if true, the machine will be automatically started
  """
  alias EcspanseStateMachine.Internal.StateSpec
  use EcspanseStateMachine.Types

  use Ecspanse.Template.Component.Timer,
    state: [
      :initial_state,
      :auto_start,
      :current_state,
      :states,
      :telemetry_start_time,
      :telemetry_state_start_time,
      is_running: false,
      duration: 5_000,
      time: 5_000,
      event: EcspanseStateMachine.Internal.Events.StateTimeout,
      mode: :once,
      paused: true
    ],
    tags: [:ecspanse_state_machine]

  # Produces a list of states visited via depth first
  defp flatten_states(states, initial_state) when is_list(states) do
    states_by_name =
      states
      |> Enum.into(%{}, &{StateSpec.name(&1), &1})

    data = %{
      visited: [],
      states_by_name: states_by_name
    }

    data = flatten_state(initial_state, data)
    Enum.reverse(data.visited)
  end

  defp flatten_state(to_state, data) when is_map(data) do
    if Enum.member?(data.visited, to_state) do
      data
    else
      data = Map.put(data, :visited, List.insert_at(data.visited, 0, to_state))
      state = Map.get(data.states_by_name, to_state)

      Enum.reduce(StateSpec.exits(state), data, fn exit_state, acc ->
        flatten_state(exit_state, acc)
      end)
    end
  end

  @doc """
  Retrieves the keyword list with the provided name
  """
  @spec get_state_spec(any(), state_name()) :: keyword() | {:error, String.t()}
  def get_state_spec(%__MODULE__{} = state_machine, name) do
    Enum.find(
      state_machine.states,
      {:error, "No state named #{inspect(name)} found"},
      &(StateSpec.name(&1) == name)
    )
  end

  def validate(component) do
    with :ok <- validate_at_least_one_state(component.states),
         :ok <- validate_all_have_names(component.states) do
      state_names = Enum.map(component.states, &StateSpec.name(&1))

      with :ok <- validate_state_specs(component.states),
           :ok <- validate_unique_state_names(state_names),
           :ok <- validate_initial_state_exists(state_names, component.initial_state),
           :ok <- validate_exit_states_exist(state_names, component.states) do
        validate_all_states_reachable(state_names, component.states, component.initial_state)
      end
    end
  end

  defp validate_all_have_names(states) do
    case Enum.all?(states, &Keyword.has_key?(&1, :name)) do
      true -> :ok
      false -> {:error, "Every state must have a name"}
    end
  end

  defp validate_at_least_one_state(states) do
    case Enum.any?(states) do
      true -> :ok
      false -> {:error, "State Machines must have at least 1 state"}
    end
  end

  defp validate_state_specs(states) do
    reasons =
      states
      |> Enum.map(&StateSpec.validate/1)
      |> Enum.filter(&(&1 != :ok))
      |> Enum.map_join("; ", fn {:error, reason} -> reason end)

    case reasons do
      "" -> :ok
      _ -> {:error, reasons}
    end
  end

  defp validate_all_states_reachable(state_names, states, initial_state) do
    visited_states = flatten_states(states, initial_state)

    unreached_states = state_names |> Enum.reject(&Enum.member?(visited_states, &1))

    if Enum.any?(unreached_states) do
      {:error, "#{Enum.join(unreached_states, ", ")} are not reachable from the starting state"}
    else
      :ok
    end
  end

  defp validate_exit_states_exist(state_names, states) do
    missing_exit_states_map =
      states
      |> Enum.reduce(%{}, fn state, acc ->
        missing_exit_states =
          StateSpec.exits(state) |> Enum.reject(&Enum.member?(state_names, &1))

        if Enum.any?(missing_exit_states) do
          Map.put(
            acc,
            StateSpec.name(state),
            "Exit states #{Enum.join(missing_exit_states, ", ")} in state #{StateSpec.name(state)} are missing."
          )
        else
          acc
        end
      end)

    if Enum.empty?(missing_exit_states_map) do
      :ok
    else
      {:error, Enum.join(Map.values(missing_exit_states_map), ", ")}
    end
  end

  defp validate_initial_state_exists(state_names, initial_state) do
    if initial_state in state_names do
      :ok
    else
      {:error, "Initial state #{initial_state} not found"}
    end
  end

  defp validate_unique_state_names(state_names) do
    duplicate_state_names =
      state_names
      |> Enum.group_by(& &1)
      |> Enum.filter(fn {_name, name_list} -> length(name_list) > 1 end)
      |> Enum.map(fn {name, _name_list} -> name end)

    if Enum.empty?(duplicate_state_names) do
      :ok
    else
      {:error, "State #{Enum.join(duplicate_state_names, ", ")} are duplicated."}
    end
  end
end

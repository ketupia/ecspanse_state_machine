defmodule EcspanseStateMachine.Components.StateMachine do
  @moduledoc """


  ## Fields
  * initial_state: the state the machine should be in at start
  * current_state: the state the machine is in now
  * states: keyword lists of states [:name, exits_to[:exit_state1, :exit_state2...]]
  """
  use Ecspanse.Component,
    state: [
      :initial_state,
      :auto_start,
      :is_running,
      :current_state,
      :states
    ],
    tags: [:ecspanse_state_machine]

  def has_exit_to?(state_machine, name, exit_to) do
    Enum.member?(get_exits_to(state_machine, name), exit_to)
  end

  def get_exits_to(state_machine, name) do
    state = Enum.find(state_machine.states, &(&1[:name] == name))
    state[:exits_to]
  end

  def has_state?(state_machine, name), do: get_state(state_machine, name) != nil

  def get_state(state_machine, name) do
    Enum.find(state_machine.states, &(&1[:name] == name))
  end

  def fetch_state(state_machine, name) do
    case get_state(state_machine, name) do
      nil -> {:error, :not_found}
      state -> {:ok, state}
    end
  end

  # @spec flatten(StateMachine.t()) :: list(atom())
  @doc """
  Produces a list of states visited via depth first
  """
  def flatten(state_machine) do
    flatten_states(state_machine.states, state_machine.initial_state)
  end

  defp flatten_states(states, initial_state) when is_list(states) do
    states_by_name =
      states
      |> Enum.into(%{}, &{&1[:name], &1})

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

      Enum.reduce(state[:exits_to], data, fn exit_state, acc ->
        flatten_state(exit_state, acc)
      end)
    end
  end

  def validate(component) do
    state_names = Enum.map(component.states, & &1[:name])

    with :ok <- validate_unique_state_names(state_names),
         :ok <- validate_initial_state_exists(state_names, component.initial_state),
         :ok <- validate_exit_states_exist(state_names, component.states),
         :ok <-
           validate_all_states_reachable(state_names, component.states, component.initial_state) do
      :ok
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
        missing_exit_states = state[:exits_to] |> Enum.reject(&Enum.member?(state_names, &1))

        if Enum.any?(missing_exit_states) do
          Map.put(
            acc,
            state[:name],
            "Exit states #{Enum.join(missing_exit_states, ", ")} in state #{state[:name]} are missing."
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

defmodule EcspanseStateMachine.Internal.Mermaid do
  @moduledoc false
  # Produces the definition of a Mermaid.js state diagram from a state_machine

  alias EcspanseStateMachine.Internal.StateSpec
  alias EcspanseStateMachine.Components
  require Logger

  @doc """
  Returns the source for a sequence diagram of the state machine
  """
  @spec as_state_diagram(any(), String.t()) :: {:ok, String.t()}
  def as_state_diagram(%Components.StateMachine{} = state_machine, title) do
    diagram =
      [
        title_block(title),
        "stateDiagram-v2",
        id_block(state_machine),
        transitions_block(state_machine)
      ]
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.join("\n")

    {:ok, diagram}
  end

  defp id_block(state_machine) do
    state_machine.states
    |> Enum.map(&StateSpec.name(&1))
    |> Enum.filter(&needs_id/1)
    |> Enum.map_join("\n", &"#{generate_id(&1)}: #{&1}")
  end

  defp needs_id(name) when is_binary(name), do: String.contains?(name, " ")
  defp needs_id(_name), do: false

  defp generate_id(name) when is_binary(name),
    do: String.replace(name, " ", "_")

  defp generate_id(name), do: name

  defp title_block(title) do
    if String.trim(title) == "" do
      ""
    else
      "---
title: #{title}
---"
    end
  end

  defp transitions_block(state_machine) do
    transitions = state_machine_transitions(state_machine)

    transitions
    |> Enum.sort(&transition_sort_fn/2)
    |> Enum.map_join("\n", &map_transition/1)
  end

  defp transition_sort_fn(a, b) do
    case {a[:from], a[:to], b[:from], b[:to]} do
      {"[*]", _, _, _} ->
        true

      {_, "[*]", _, _} ->
        false

      # this can't happen because the list starts with the initial state
      # {_, _, "[*]", _} ->
      # false

      {_, _, _, "[*]"} ->
        true

      {a_from, a_to, b_from, b_to} ->
        case a_from == b_from do
          true -> a_to < b_to
          false -> a_from < b_from
        end
    end
  end

  defp map_transition(transition) do
    "#{generate_id(transition[:from])} --> #{generate_id(transition[:to])}" <>
      if transition[:timeout] do
        ": ⏲️"
      else
        ""
      end
  end

  defp state_machine_transitions(state_machine) do
    Enum.reduce(state_machine.states, [], fn state, acc ->
      if Enum.empty?(StateSpec.exits(state)) do
        List.insert_at(
          acc,
          0,
          Keyword.new(from: StateSpec.name(state), to: "[*]", timeout: false)
        )
      else
        Enum.reduce(
          StateSpec.exits(state),
          acc,
          &List.insert_at(
            &2,
            0,
            Keyword.new(
              from: StateSpec.name(state),
              to: &1,
              timeout: StateSpec.has_timeout?(state) and &1 == StateSpec.default_exit(state)
            )
          )
        )
      end
    end)
    |> List.insert_at(
      0,
      Keyword.new(from: "[*]", to: state_machine.initial_state, timeout: false)
    )
  end
end

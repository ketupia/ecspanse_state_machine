defmodule EcspanseStateMachine.Internal.Mermaid do
  @moduledoc """
  Produces the definition of a Mermaid.js state diagram from a state_machine
  """
  alias EcspanseStateMachine.Components
  require Logger

  @spec as_state_diagram(Ecspanse.Entity.id(), String.t()) :: String.t() | {:error, :not_found}
  def as_state_diagram(entity_id, title \\ nil) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id) do
      "stateDiagram-v2
#{title_block(title)}
#{transitions_block(entity)}"
    end
  end

  defp title_block(title) do
    if title == nil do
      ""
    else
      "---
title: #{title}
---"
    end
  end

  defp transitions_block(entity) do
    with {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      transitions = state_machine_transitions(state_machine)

      transitions =
        if Ecspanse.Query.has_component?(entity, Components.StateTimer) do
          {:ok, timer} =
            Ecspanse.Query.fetch_component(entity, Components.StateTimer)

          add_timeout_transitions(timer.timeouts, transitions)
        else
          transitions
        end

      transitions
      |> Enum.sort(&transition_sort_fn/2)
      |> Enum.map_join("\n", &format_transition/1)
    end
  end

  defp transition_sort_fn(a, b) do
    case {a[:from], a[:to], b[:from], b[:to]} do
      {"[*]", _, _, _} ->
        true

      {_, "[*]", _, _} ->
        false

      {_, _, "[*]", _} ->
        false

      {_, _, _, "[*]"} ->
        true

      {a_from, a_to, b_from, b_to} ->
        case Atom.to_string(a_from) == Atom.to_string(b_from) do
          true -> Atom.to_string(a_to) < Atom.to_string(b_to)
          false -> Atom.to_string(a_from) < Atom.to_string(b_from)
        end
    end
  end

  defp add_timeout_transitions(timeouts, transitions) do
    Enum.reduce(timeouts, transitions, fn timeout, acc ->
      existing_transition =
        Enum.find(acc, &(&1[:from] == timeout[:name] and &1[:to] == timeout[:exits_to]))

      acc =
        if existing_transition do
          List.delete(acc, existing_transition)
        else
          acc
        end

      List.insert_at(acc, 0, from: timeout[:name], to: timeout[:exits_to], timeout: true)
    end)
  end

  defp format_transition(transition) do
    "  #{transition[:from]} --> #{transition[:to]}" <>
      if transition[:timeout] do
        ": ⏲️"
      else
        ""
      end
  end

  defp state_machine_transitions(state_machine) do
    Enum.reduce(state_machine.states, [], fn state, acc ->
      if is_nil(state[:exits_to]) || Enum.empty?(state[:exits_to]) do
        List.insert_at(acc, 0, Keyword.new(from: state[:name], to: "[*]", timeout: false))
      else
        Enum.reduce(
          state[:exits_to],
          acc,
          &List.insert_at(&2, 0, Keyword.new(from: state[:name], to: &1, timeout: false))
        )
      end
    end)
    |> List.insert_at(
      0,
      Keyword.new(from: "[*]", to: state_machine.initial_state, timeout: false)
    )
  end
end

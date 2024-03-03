defmodule EcspanseStateMachine.Internal.Mermaid do
  @moduledoc """
  Converts a graph and it's nodes into the source for a Mermaid state diagram
  """
  alias EcspanseStateMachine.Internal.Components
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.GraphFlattener

  @spec as_state_diagram(Ecspanse.Entity.t()) :: String.t()
  def as_state_diagram(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      node_transitions_map =
        Locator.get_nodes(graph_entity)
        |> Enum.into(%{}, &{&1.name, encode_transitions(&1)})

      flattened_node_names = GraphFlattener.flatten(graph_entity)

      node_transitions =
        Enum.map_join(flattened_node_names, "\n", &Map.get(node_transitions_map, &1))

      "---
title: #{graph_component.name}
---
stateDiagram-v2
  [*] --> #{graph_component.starting_node_name}
#{node_transitions}
"
    end
  end

  defp encode_transitions(node_component) do
    if is_nil(node_component.allowed_exit_node_names) ||
         Enum.empty?(node_component.allowed_exit_node_names) do
      "  #{node_component.name} --> [*]"
    else
      node_component.allowed_exit_node_names
      |> Enum.map_join("\n", &encode_transition(node_component, &1))
    end
  end

  defp encode_transition(node_component, exit_node_name) do
    if node_component.has_timer and node_component.timeout_node_name == exit_node_name do
      "  #{node_component.name} --> #{exit_node_name}: ⏲️"
    else
      "  #{node_component.name} --> #{exit_node_name}"
    end
  end
end

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
        Locator.get_nodes(graph_component)
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

  defp encode_transitions(node) do
    if is_nil(node.allowed_exit_node_names) || Enum.empty?(node.allowed_exit_node_names) do
      "  #{node.name} --> [*]"
    else
      node.allowed_exit_node_names
      |> Enum.map_join("\n", &encode_transition(node, &1))
    end
  end

  defp encode_transition(node, exit_node_name) do
    if node.has_timer and node.timeout_node_name == exit_node_name do
      "  #{node.name} --> #{exit_node_name}: ⏲️"
    else
      "  #{node.name} --> #{exit_node_name}"
    end
  end
end

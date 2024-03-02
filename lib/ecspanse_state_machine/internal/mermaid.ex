defprotocol EcspanseStateMachine.Internal.Mermaid do
  @spec to_state_diagram(t) :: String.t()
  def to_state_diagram(value)
end

defimpl EcspanseStateMachine.Internal.Mermaid, for: EcspanseStateMachine.Internal.Components.Graph do
  def to_state_diagram(graph) do
    "---
title: #{graph.name}
---
stateDiagram-v2
  [*] --> #{graph.starting_node_name}"
  end
end

defimpl EcspanseStateMachine.Internal.Mermaid, for: EcspanseStateMachine.Internal.Components.Node do
  def to_state_diagram(node) do
    to_state_diagram(node, node.allowed_exit_node_names)
  end

  def to_state_diagram(node, []), do: "  #{node.name} --> [*]"

  def to_state_diagram(node, allowed_exit_node_names) do
    Enum.map_join(allowed_exit_node_names, "\n", &encode_transition(node, &1))
  end

  defp encode_transition(node, exit_node_name) do
    if node.has_timer and node.timeout_node_name == exit_node_name do
      "  #{node.name} --> #{exit_node_name}: ⏲️"
    else
      "  #{node.name} --> #{exit_node_name}"
    end
  end
end

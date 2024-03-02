defprotocol EcspanseStateMachine.Mermaid do
  @spec to_state_diagram(t) :: String.t()
  def to_state_diagram(value)
end

defimpl EcspanseStateMachine.Mermaid, for: EcspanseStateMachine.Components.Graph do
  def to_state_diagram(graph) do
    "---
title: #{graph.name}
---
stateDiagram-v2
  [*] --> #{graph.starting_node_name}"
  end
end

defimpl EcspanseStateMachine.Mermaid, for: EcspanseStateMachine.Components.Node do
  def to_state_diagram(node) do
    Enum.map_join(node.allowed_exit_node_names, "\n", &encode_transition(node, &1))
  end

  defp encode_transition(node, exit_node_name) do
    if node.has_timer and node.timeout_node_name == exit_node_name do
      "  #{node.name} --> #{exit_node_name}: ⏲️"
    else
      "  #{node.name} --> #{exit_node_name}"
    end
  end
end

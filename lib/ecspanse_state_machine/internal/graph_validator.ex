defmodule EcspanseStateMachine.Internal.GraphValidator do
  @moduledoc """
  Validates a graph
  * all nodes must exist
  * all nodes must have a unique name
  * all exit nodes must exist
  * all nodes must be reachable
  """
  alias EcspanseStateMachine.Internal.Components
  @spec validate(Components.Graph.t()) :: :ok | {:error, String.t()}
  def validate(graph_component) do
    graph_entity = Ecspanse.Query.get_component_entity(graph_component)

    nodes =
      Ecspanse.Query.list_tagged_components_for_children(graph_entity, [
        :ecspanse_state_machine_node
      ])

    node_names = Enum.map(nodes, & &1.name)

    with :ok <- verify_unique_names(graph_component, node_names),
         :ok <-
           verify_starting_node_exists(
             graph_component,
             graph_component.starting_node_name,
             node_names
           ),
         :ok <- verify_allowed_exit_nodes_exist(graph_component, nodes, node_names),
         :ok <- verify_all_nodes_reachable(graph_component, nodes, node_names) do
      :ok
    end
  end

  defp verify_all_nodes_reachable(graph_component, nodes, node_names) do
    starting_node = Enum.find(nodes, &(&1.name == graph_component.starting_node_name))

    reached_node_names = gather_reached_node_names(nodes, [], starting_node)

    unvisited_node_names = Enum.reject(node_names, &(&1 in reached_node_names))

    if Enum.empty?(unvisited_node_names) do
      :ok
    else
      {:error,
       "Unreachable nodes: #{Enum.join(unvisited_node_names, ", ")} in #{graph_component.name}"}
    end
  end

  defp gather_reached_node_names(nodes, reached_node_names, visit_node) do
    if visit_node.name in reached_node_names do
      reached_node_names
    else
      reached_node_names =
        reached_node_names ++ [visit_node.name]

      visit_node.allowed_exit_node_names
      |> Enum.reduce(reached_node_names, fn exit_node_name, acc ->
        gather_reached_node_names(nodes, acc, Enum.find(nodes, &(&1.name == exit_node_name)))
      end)
    end
  end

  defp verify_allowed_exit_nodes_exist(graph_component, nodes, node_names) do
    error_reasons =
      nodes
      |> Enum.map(fn node ->
        missing_exit_node_names =
          node.allowed_exit_node_names
          |> Enum.reject(&(&1 in node_names))

        if Enum.empty?(missing_exit_node_names) do
          nil
        else
          "Exit nodes, #{Enum.join(missing_exit_node_names, ", ")} in #{node.name} do not exist in graph #{graph_component.name}"
        end
      end)
      |> Enum.reject(&(&1 == nil))

    if Enum.empty?(error_reasons) do
      :ok
    else
      {:error, Enum.join(error_reasons, ", ")}
    end
  end

  defp verify_starting_node_exists(graph_component, node_name, node_names) do
    if node_name in node_names do
      :ok
    else
      {:error, "Starting node #{node_name} does not exist in graph #{graph_component.name}"}
    end
  end

  def verify_unique_names(graph_component, node_names) do
    duplicate_node_names =
      node_names
      |> Enum.group_by(& &1)
      |> Enum.filter(fn {_name, name_list} -> length(name_list) > 1 end)
      |> Enum.map(fn {name, _name_list} -> name end)

    if Enum.empty?(duplicate_node_names) do
      :ok
    else
      {:error,
       "Node names #{Enum.join(duplicate_node_names, ", ")} are duplicated in #{graph_component.name}"}
    end
  end
end

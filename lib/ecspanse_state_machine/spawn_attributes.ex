defmodule EcspanseStateMachine.SpawnAttributes do
  defmodule Timer do
    @moduledoc """
    The properties needed to define a node's timeout timer
    * duration: the timer's duration in milliseconds
    * exits_to: the name of the node to transition to when the timer elapses
    """
    @enforce_keys [:duration, :exits_to]
    defstruct duration: nil, exits_to: nil

    @type t :: %__MODULE__{
            duration: pos_integer(),
            exits_to: atom()
          }
  end

  defmodule Node do
    @moduledoc """
    The properties needed to defined a node without a timer
    * name: the name of the node
    * exits_to: the list of node names you can transition to from this node
    """
    @enforce_keys [:name]
    defstruct name: nil, exits_to: [], timer: nil

    @type t :: %__MODULE__{
            name: atom(),
            exits_to: list(atom()),
            timer: EcspanseStateMachine.SpawnDefinition.Timer.t()
          }
  end

  defmodule Graph do
    @moduledoc """
    the properties needed to spawn a graph
    * name: the name of the graph
    * starting_node_name: the name of the node to enter when the graph starts
    * metadata: any data you want passed back to you on node transitions
    * auto_start: the graph will start after being spawned
    """
    @enforce_keys [:name, :starting_node, :nodes]
    defstruct name: nil, starting_node: nil, metadata: nil, auto_start: false, nodes: nil

    @type t :: %__MODULE__{
            name: atom(),
            starting_node: atom(),
            metadata: any(),
            auto_start: boolean(),
            nodes: list(EcspanseStateMachine.SpawnDefinition.Node.t())
          }

    def validate(graph) do
      node_names = Enum.map(graph.nodes, & &1.name)

      with :ok <- validate_unique_node_names(node_names),
           :ok <- validate_starting_node_exist(node_names, graph.starting_node),
           :ok <- validate_exit_nodes(node_names, graph.nodes),
           :ok <- validate_timer_exits(node_names, graph.nodes),
           :ok <- validate_all_nodes_reachable(node_names, graph.nodes, graph.starting_node) do
        :ok
      end
    end

    defp validate_all_nodes_reachable(node_names, nodes, starting_node) do
      data =
        traverse(starting_node, %{
          visited: [],
          nodes_by_name: Enum.into(nodes, %{}, &{&1.name, &1})
        })

      unreached_nodes = node_names |> Enum.reject(&Enum.member?(data.visited, &1))

      if Enum.any?(unreached_nodes) do
        {:error, "#{Enum.join(unreached_nodes, ", ")} are not reachable from the starting node"}
      else
        :ok
      end
    end

    def traverse(node_name, data) do
      if Enum.member?(data.visited, node_name) do
        data
      else
        data = Map.put(data, :visited, List.insert_at(data.visited, 0, node_name))
        node = Map.get(data.nodes_by_name, node_name)

        data =
          Enum.reduce(node.exits_to, data, fn exit_node_name, acc ->
            traverse(exit_node_name, acc)
          end)

        if node.timer == nil do
          data
        else
          traverse(node.timer.exits_to, data)
        end
      end
    end

    defp validate_timer_exits(node_names, nodes) do
      missing_timer_exit_reasons =
        nodes
        |> Enum.reject(&(&1.timer == nil || Enum.member?(node_names, &1.timer.exits_to)))

      if Enum.empty?(missing_timer_exit_reasons) do
        :ok
      else
        {:error,
         Enum.map_join(
           missing_timer_exit_reasons,
           ", ",
           &"Timer exit node #{&1.timer.exits_to} does not exist"
         )}
      end
    end

    defp validate_exit_nodes(node_names, nodes) do
      missing_exit_nodes_map =
        nodes
        |> Enum.reduce(%{}, fn node, acc ->
          missing_exit_nodes = node.exits_to |> Enum.reject(&Enum.member?(node_names, &1))

          if Enum.any?(missing_exit_nodes) do
            Map.put(
              acc,
              node.name,
              "Exit nodes #{Enum.join(missing_exit_nodes, ", ")} in node #{node.name} are missing"
            )
          else
            acc
          end
        end)

      if Enum.empty?(missing_exit_nodes_map) do
        :ok
      else
        {:error, Enum.join(Map.values(missing_exit_nodes_map), ", ")}
      end
    end

    defp validate_starting_node_exist(node_names, starting_node_name) do
      if starting_node_name in node_names do
        :ok
      else
        {:error, "Starting node #{starting_node_name} does not exist"}
      end
    end

    defp validate_unique_node_names(node_names) do
      duplicate_node_names =
        node_names
        |> Enum.group_by(& &1)
        |> Enum.filter(fn {_name, name_list} -> length(name_list) > 1 end)
        |> Enum.map(fn {name, _name_list} -> name end)

      if Enum.empty?(duplicate_node_names) do
        :ok
      else
        {:error, "Node names #{Enum.join(duplicate_node_names, ", ")} are duplicated."}
      end
    end
  end
end

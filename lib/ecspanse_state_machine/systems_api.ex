defmodule EcspanseStateMachine.SystemsApi do
  @moduledoc """
  The Api to use from other Ecspanse systems
  """
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Entities

  @spec spawn_graph(atom(), atom(), any()) :: {:ok, Ecspanse.Entity.t()}
  @doc """
  Spawns a graph entity and returns the entity_id
  """
  def spawn_graph(graph_name, starting_node_name, reference \\ nil) do
    {:ok,
     Entities.Graph.blueprint(graph_name, starting_node_name, reference)
     |> Ecspanse.Command.spawn_entity!()}
  end

  @spec spawn_node(Ecspanse.Entity.t(), atom(), list(atom())) ::
          {:ok, Ecspanse.Entity.t()} | {:error, :graph_is_running}
  @doc """
  Will spawn the node into the graph unless the graph is running
  """
  def spawn_node(graph_entity, node_name, allowed_exit_node_names \\ []) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      if graph_component.is_running do
        {:error, :graph_is_running}
      else
        {:ok,
         Entities.Node.blueprint(graph_entity, node_name, allowed_exit_node_names)
         |> Ecspanse.Command.spawn_entity!()}
      end
    end
  end

  @spec spawn_node(Ecspanse.Entity.t(), atom(), list(atom()), pos_integer(), atom()) ::
          {:ok, Ecspanse.Entity.t()} | {:error, :graph_is_running}
  @doc """
  Will spawn the node with a timeout timer into the graph unless the graph is running
  """
  def spawn_node(
        graph_entity,
        node_name,
        allowed_exit_node_names \\ [],
        timeout_duration,
        timeout_node_name
      ) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      if graph_component.is_running do
        {:error, :graph_is_running}
      else
        {:ok,
         Entities.Node.blueprint(
           graph_entity,
           node_name,
           allowed_exit_node_names,
           timeout_duration,
           timeout_node_name
         )
         |> Ecspanse.Command.spawn_entity!()}
      end
    end
  end
end

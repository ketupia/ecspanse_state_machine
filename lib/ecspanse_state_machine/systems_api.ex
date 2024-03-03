defmodule EcspanseStateMachine.SystemsApi do
  @moduledoc """
  The Api to use from other Ecspanse systems to spawn and despawn entities.
  """
  alias EcspanseStateMachine.Internal.Spawner

  @spec despawn_graph(Ecspanse.Entity.id()) :: :ok | {:error, :not_found}
  def despawn_graph(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      Spawner.despawn_graph(graph_entity)
    end
  end

  @spec spawn_graph(atom(), atom(), any()) :: {:ok, Ecspanse.Entity.id()}
  @doc """
  Spawns a graph entity and returns the entity_id
  """
  def spawn_graph(graph_name, starting_node_name, metadata \\ nil) do
    Spawner.spawn_graph(graph_name, starting_node_name, metadata)
  end

  @spec spawn_node(Ecspanse.Entity.id(), atom(), list(atom())) ::
          :ok | {:error, :graph_is_running} | {:error, :not_found}
  @doc """
  Will spawn the node into the graph unless the graph is running
  """
  def spawn_node(graph_entity_id, node_name, allowed_exit_node_names \\ []) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      Spawner.spawn_node(graph_entity, node_name, allowed_exit_node_names)
    end
  end

  @spec spawn_node(Ecspanse.Entity.id(), atom(), list(atom()), pos_integer(), atom()) ::
          :ok | {:error, :graph_is_running} | {:error, :not_found}
  @doc """
  Will spawn the node with a timeout timer into the graph unless the graph is running
  """
  def spawn_node(
        graph_entity_id,
        node_name,
        allowed_exit_node_names \\ [],
        timeout_duration,
        timeout_node_name
      ) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      Spawner.spawn_node(
        graph_entity,
        node_name,
        allowed_exit_node_names,
        timeout_duration,
        timeout_node_name
      )
    end
  end
end

defmodule EcspanseStateMachine.Internal.Spawner do
  @moduledoc """
  Functions to spawn and despawn graphs and nodes
  """
  alias EcspanseStateMachine.Internal.Entities
  alias EcspanseStateMachine.Internal.Components
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Engine

  @spec despawn_graph(Ecspanse.Entity.t()) :: :ok | {:error, :not_found}
  def despawn_graph(graph_entity) do
    Engine.maybe_stop_graph(graph_entity)

    nodes = Locator.get_nodes(graph_entity)

    nodes
    |> Enum.map(&Ecspanse.Query.get_component_entity/1)
    |> Ecspanse.Command.despawn_entities!()

    Ecspanse.Command.despawn_entity!(graph_entity)
  end

  @spec spawn_graph(atom(), atom(), any()) :: {:ok, Ecspanse.Entity.id()}
  @doc """
  Spawns a graph entity and returns the entity_id
  """
  def spawn_graph(graph_name, starting_node_name, metadata \\ nil) do
    graph_entity =
      Entities.Graph.blueprint(graph_name, starting_node_name, metadata)
      |> Ecspanse.Command.spawn_entity!()

    {:ok, graph_entity.id}
  end

  @spec spawn_node(Ecspanse.Entity.t(), atom(), list(atom())) ::
          :ok | {:error, :graph_is_running} | {:error, :not_found}
  @doc """
  Will spawn the node into the graph unless the graph is running
  """
  def spawn_node(graph_entity, node_name, allowed_exit_node_names \\ []) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      if graph_component.is_running do
        {:error, :graph_is_running}
      else
        Entities.Node.blueprint(graph_entity, node_name, allowed_exit_node_names)
        |> Ecspanse.Command.spawn_entity!()

        :ok
      end
    end
  end

  @spec spawn_node(Ecspanse.Entity.t(), atom(), list(atom()), pos_integer(), atom()) ::
          :ok | {:error, :graph_is_running} | {:error, :not_found}
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
        Entities.Node.blueprint(
          graph_entity,
          node_name,
          allowed_exit_node_names,
          timeout_duration,
          timeout_node_name
        )
        |> Ecspanse.Command.spawn_entity!()

        :ok
      end
    end
  end
end

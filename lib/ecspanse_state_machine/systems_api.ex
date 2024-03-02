defmodule EcspanseStateMachine.SystemsApi do
  @moduledoc """
  The Api to use from other Ecspanse systems
  """
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Internal.Components
  alias EcspanseStateMachine.Internal.Entities

  @spec despawn_graph(Ecspanse.Entity.id() | Ecspanse.Entity.t()) :: {:ok} | {:error, :not_found}
  def despawn_graph(graph_entity_id) when is_binary(graph_entity_id) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      despawn_graph(graph_entity)
    end
  end

  def despawn_graph(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      Engine.maybe_stop_graph(graph_component)

      {:ok, nodes} = Locator.fetch_nodes(graph_component.name)

      nodes
      |> Enum.map(&Ecspanse.Query.get_component_entity/1)
      |> Ecspanse.Command.despawn_entities!()

      Ecspanse.Command.despawn_entity!(graph_entity)
    end
  end

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

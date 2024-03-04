defmodule EcspanseStateMachine.Internal.Spawner do
  @moduledoc """
  Functions to spawn and despawn graphs and nodes
  """
  alias EcspanseStateMachine.Internal.Entities
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Engine

  @spec spawn_graph(EcspanseStateMachine.SpawnAttributes.Graph.t()) ::
          {:ok, Ecspanse.Entity.id()} | {:error, String.t()}
  def spawn_graph(graph_attributes) do
    with :ok <- EcspanseStateMachine.SpawnAttributes.Graph.validate(graph_attributes) do
      graph_entity =
        Entities.Graph.blueprint(
          graph_attributes.name,
          graph_attributes.starting_node,
          graph_attributes.auto_start,
          graph_attributes.metadata
        )
        |> Ecspanse.Command.spawn_entity!()

      graph_attributes.nodes
      |> Enum.each(fn node_attr ->
        if node_attr.timer == nil do
          Entities.Node.blueprint(graph_entity, node_attr.name, node_attr.exits_to)
          |> Ecspanse.Command.spawn_entity!()
        else
          Entities.Node.blueprint(
            graph_entity,
            node_attr.name,
            node_attr.exits_to,
            node_attr.timer.duration,
            node_attr.timer.exits_to
          )
          |> Ecspanse.Command.spawn_entity!()
        end
      end)

      if graph_attributes.auto_start do
        Engine.maybe_start_graph(graph_entity)
      end

      {:ok, graph_entity.id}
    end
  end

  @spec despawn_graph(Ecspanse.Entity.t()) :: :ok | {:error, :not_found}
  def despawn_graph(graph_entity) do
    Engine.maybe_stop_graph(graph_entity)

    nodes = Locator.get_nodes(graph_entity)

    nodes
    |> Enum.map(&Ecspanse.Query.get_component_entity/1)
    |> Ecspanse.Command.despawn_entities!()

    Ecspanse.Command.despawn_entity!(graph_entity)
  end
end

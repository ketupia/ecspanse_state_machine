defmodule EcspanseStateMachine.Projections.Graph do
  @moduledoc """
  The projection for a graph
  """
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Components

  use Ecspanse.Projection,
    fields: [
      :entity_id,
      :name,
      :reference,
      :starting_node_name,
      :is_running,
      :current_node_name,
      :current_node
    ]

  @impl true
  def project(%{entity_id: entity_id} = _attrs) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      current_node_map = map_current_node(graph_component)

      fields =
        [
          {:entity_id, graph_entity.id},
          {:name, graph_component.name},
          {:reference, graph_component.reference},
          {:starting_node_name, graph_component.starting_node_name},
          {:is_running, graph_component.is_running},
          {:current_node_name, graph_component.current_node_name},
          {:current_node, current_node_map}
        ]

      # , {:nodes, map_nodes(graph_component)}

      {:ok, struct!(__MODULE__, fields)}
    else
      _ -> :error
    end
  end

  # defp map_nodes(graph_component) do
  #   Locator.fetch_nodes(graph_component.name)
  #   |> Enum.map(&project_node/1)
  # end

  defp map_current_node(graph_component) do
    if graph_component.current_node_name == nil do
      nil
    else
      {:ok, node_component} =
        Locator.fetch_node_component(graph_component, graph_component.current_node_name)

      project_node(node_component)
    end
  end

  defp project_node(node_component) do
    map =
      Map.take(node_component, [
        :name,
        :allowed_exit_node_names,
        :has_timer,
        :timeout_node_name
      ])

    if node_component.has_timer do
      node_entity = Ecspanse.Query.get_component_entity(node_component)
      {:ok, timer_component} = Components.NodeTimeoutTimer.fetch(node_entity)
      Map.put(map, :timer, Map.take(timer_component, [:duration, :paused]))
    else
      map
    end
  end

  @impl true
  def on_change(%{client_pid: pid} = _attrs, new_projection, _previous_projection) do
    # when the projection changes, send it to the client
    send(pid, {:projection_updated, new_projection})
  end
end

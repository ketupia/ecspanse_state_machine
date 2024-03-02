defmodule EcspanseStateMachine.Projections.Graph do
  @moduledoc """
  The projection for a graph
  """
  alias EcspanseStateMachine.Internals.Locator
  alias EcspanseStateMachine.Components

  use Ecspanse.Projection,
    fields: [
      :entity_id,
      :name,
      :starting_node_name,
      :is_running,
      :current_node_name,
      :current_node
    ]

  @impl true
  def project(%{entity_id: entity_id} = _attrs) do
    IO.inspect(entity_id, label: "projecting graph")

    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      current_node_map = map_current_node(graph_component)

      fields =
        Map.to_list(graph_component) ++
          [{:entity_id, entity_id}, {:current_node, current_node_map}]

      {:ok, struct!(__MODULE__, fields)}
    else
      _ -> :error
    end
  end

  defp map_current_node(graph_component) do
    if graph_component.current_node_name == nil do
      nil
    else
      {:ok, node_component} =
        Locator.fetch_node_component(graph_component, graph_component.current_node_name)

      map =
        Map.take(node_component, [
          :name,
          :allowed_exit_node_names,
          :has_timer,
          :timeout_node_name
        ])

      node_entity = Ecspanse.Query.get_component_entity(node_component)
      map = Map.put(map, :entity_id, node_entity.id)

      if node_component.has_timer do
        {:ok, timer_component} = Components.NodeTimeoutTimer.fetch(node_entity)
        Map.put(map, :timeout_timer, Map.take(timer_component, [:duration, :time, :paused]))
      else
        map
      end
    end
  end

  @impl true
  def on_change(%{client_pid: pid} = _attrs, new_projection, _previous_projection) do
    # when the projection changes, send it to the client
    send(pid, {:projection_updated, new_projection})
  end
end

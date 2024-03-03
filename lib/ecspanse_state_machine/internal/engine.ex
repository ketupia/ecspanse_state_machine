defmodule EcspanseStateMachine.Internal.Engine do
  @moduledoc """
  This is the core logic for the operations of the state machine.
  """
  require Logger
  alias EcspanseStateMachine.Internal.Components
  alias EcspanseStateMachine.Internal.GraphValidator
  alias EcspanseStateMachine.Internal.Locator

  @spec maybe_start_graph(Ecspanse.Entity.t()) :: :ok
  @doc """
  Starts the graph component if it is not already running.
  First validates the graph component by calling GraphValidator.validate/1.
  If validation passes, starts the graph by calling start_graph/1.
  If validation fails, an Error Log is written.
  """
  def maybe_start_graph(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      unless graph_component.is_running do
        case GraphValidator.validate(graph_entity) do
          :ok ->
            start_graph(graph_entity, graph_component)

          {:error, reason} ->
            Logger.error("Invalid Graph! #{reason},  metadata: #{graph_component.metadata}", %{
              graph_entity_id: Ecspanse.Query.get_component_entity(graph_component).id,
              name: graph_component.name,
              metadata: graph_component.metadata,
              reason: reason
            })
        end
      end
    end
  end

  @spec start_graph(Ecspanse.Entity.t(), Components.Graph.t()) :: :ok
  defp start_graph(graph_entity, graph_component) do
    with {:ok, next_node_component} <-
           Locator.fetch_node_component_by_name(graph_entity, graph_component.starting_node_name) do
      Ecspanse.Command.update_component!(graph_component,
        is_running: true
      )

      {:ok, graph_component} = Components.Graph.fetch(graph_entity)

      Ecspanse.event(
        {EcspanseStateMachine.Events.GraphStarted,
         [
           entity_id: graph_entity.id,
           name: graph_component.name,
           metadata: graph_component.metadata
         ]}
      )

      transition_nodes(graph_entity, graph_component, nil, next_node_component, :graph_started)
    end
  end

  @spec maybe_stop_graph(Ecspanse.Entity.t()) :: :ok
  @doc """
  Stops the graph if it is currently running by calling stop_graph.
  """
  def maybe_stop_graph(graph_entity) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      if graph_component.is_running do
        stop_graph(graph_entity, graph_component)
      end
    end
  end

  @spec stop_graph(Ecspanse.Entity.t(), Components.Graph.t()) :: :ok
  defp stop_graph(graph_entity, graph_component) do
    with {:ok, current_node_component} <-
           Locator.fetch_node_component_by_name(graph_entity, graph_component.current_node_name) do
      stop_timer(current_node_component)
    end

    Ecspanse.Command.update_component!(graph_component,
      is_running: false
    )

    Ecspanse.event(
      {EcspanseStateMachine.Events.GraphStopped,
       [
         entity_id: graph_entity.id,
         name: graph_component.name,
         metadata: graph_component.metadata
       ]}
    )
  end

  @spec start_timer(Components.Node.t()) :: :ok
  defp start_timer(node_component) do
    if node_component.has_timer do
      node_entity = Ecspanse.Query.get_component_entity(node_component)

      {:ok, timer_component} =
        Components.NodeTimeoutTimer.fetch(node_entity)

      Ecspanse.Command.update_component!(timer_component,
        time: timer_component.duration,
        paused: false
      )
    else
      :ok
    end
  end

  @spec stop_timer(Components.Node.t()) :: :ok
  defp stop_timer(node_component) do
    if node_component.has_timer do
      node_entity = Ecspanse.Query.get_component_entity(node_component)

      {:ok, timer_component} =
        Components.NodeTimeoutTimer.fetch(node_entity)

      Ecspanse.Command.update_component!(timer_component,
        paused: true
      )
    else
      :ok
    end
  end

  @spec maybe_transition_nodes(
          Ecspanse.Entity.t(),
          Components.Node.t(),
          Components.Node.t(),
          atom()
        ) ::
          :ok | {:error, :not_running | :invalid_exit} | {:error, :not_found}
  @doc """
  Executes the transition between the given current and next node components
  is valid based on the graph state and allowed transitions. .
  """
  def maybe_transition_nodes(graph_entity, current_node_component, next_node_component, reason) do
    with {:ok, graph_component} <- Components.Graph.fetch(graph_entity) do
      if ensure_graph_is_running(graph_entity, graph_component) and
           ensure_current_node_matches(graph_entity, graph_component, current_node_component) and
           ensure_is_allowed_exit(
             graph_entity,
             graph_component,
             current_node_component,
             next_node_component
           ) do
        transition_nodes(
          graph_entity,
          graph_component,
          current_node_component,
          next_node_component,
          reason
        )
      end
    end
  end

  defp ensure_is_allowed_exit(graph_entity, graph_component, nil, target_node_component) do
    if graph_component.starting_node_name == target_node_component.name do
      true
    else
      Logger.warning(
        "Graph #{graph_entity.id}, #{graph_component.name} current node is nil.  The only allowed exit is to the start node, #{graph_component.starting_node_name} and not #{target_node_component.name}"
      )

      false
    end
  end

  defp ensure_is_allowed_exit(
         graph_entity,
         graph_component,
         current_node_component,
         target_node_component
       ) do
    if target_node_component.name in current_node_component.allowed_exit_node_names do
      true
    else
      Logger.warning(
        "#{target_node_component.name} is not in the allowed exit nodes #{Enum.join(current_node_component.allowed_exit_node_names, ", ")} for #{current_node_component.name} in #{} Graph #{graph_entity.id}, #{graph_component.name} current node is nil.  The only allowed exit is to the start node, #{graph_component.starting_node_name} and not #{target_node_component.name}"
      )
    end
  end

  defp ensure_current_node_matches(graph_entity, graph_component, node_component) do
    if graph_component.current_node_name == node_component.name do
      true
    else
      Logger.warning(
        "Graph #{graph_entity.id}, #{graph_component.name} current node is #{graph_component.current_node_name} and not #{node_component.name}"
      )

      false
    end
  end

  defp ensure_graph_is_running(graph_entity, graph_component) do
    if graph_component.is_running do
      true
    else
      Logger.warning("Graph #{graph_entity.id}, #{graph_component.name} not running")
      false
    end
  end

  @spec transition_nodes(
          Ecspanse.Entity.t(),
          Components.Graph.t(),
          Components.Node.t(),
          Components.Node.t(),
          atom()
        ) ::
          :ok
  defp transition_nodes(
         graph_entity,
         graph_component,
         current_node_component,
         next_node_component,
         reason
       ) do
    unless current_node_component == nil do
      stop_timer(current_node_component)
    end

    current_node_name =
      case current_node_component do
        nil -> nil
        current_node_component -> current_node_component.name
      end

    Ecspanse.Command.update_component!(graph_component,
      current_node_name: next_node_component.name
    )

    {:ok, graph_component} = Components.Graph.fetch(graph_entity)

    Ecspanse.event(
      {EcspanseStateMachine.Events.NodeTransition,
       [
         graph_entity_id: graph_entity.id,
         graph_name: graph_component.name,
         graph_metadata: graph_component.metadata,
         previous_node_name: current_node_name,
         current_node_name: next_node_component.name,
         reason: reason
       ]}
    )

    if Enum.empty?(next_node_component.allowed_exit_node_names) do
      stop_graph(graph_entity, graph_component)
    else
      start_timer(next_node_component)
    end
  end
end

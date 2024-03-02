defmodule EcspanseStateMachine.Internal.Engine do
  @moduledoc """
  This is the core logic for the operations of the state machine.
  """
  alias EcspanseStateMachine.Internal.Components
  alias EcspanseStateMachine.Internal.GraphValidator
  alias EcspanseStateMachine.Internal.Locator

  @spec maybe_start_graph(Components.Graph.t()) :: :ok
  @doc """
  Starts the graph if it is not already running and the graph is valid.
  Emits InvalidGraph when the graph is not valid
  """
  def maybe_start_graph(graph_component) do
    unless graph_component.is_running do
      case GraphValidator.validate(graph_component) do
        :ok ->
          start_graph(graph_component)

        {:error, reason} ->
          Ecspanse.event(EcspanseStateMachine.Events.InvalidGraph,
            graph_entity_id: Ecspanse.Query.get_component_entity(graph_component).id,
            graph_name: graph_component.name,
            graph_reference: graph_component.reference,
            reason: reason
          )
      end
    end
  end

  @spec start_graph(Components.Graph.t()) :: :ok
  defp start_graph(graph_component) do
    Ecspanse.Command.update_component!(graph_component,
      is_running: true
    )

    graph_component = Locator.get_graph_component_by_name(graph_component.name)

    Ecspanse.event(
      {EcspanseStateMachine.Events.GraphStarted,
       [
         graph_entity_id: Ecspanse.Query.get_component_entity(graph_component).id,
         graph_name: graph_component.name,
         graph_reference: graph_component.reference
       ]}
    )

    next_node_component =
      Locator.get_node_component(graph_component, graph_component.starting_node_name)

    transition_nodes(graph_component, nil, next_node_component, :graph_started)
  end

  @spec maybe_stop_graph(Components.Graph.t()) :: :ok
  @doc """
  Stops the graph if it is running.
  """
  def maybe_stop_graph(graph_component) do
    if graph_component.is_running do
      stop_graph(graph_component)
    end
  end

  @spec stop_graph(Components.Graph.t()) :: :ok
  defp stop_graph(graph_component) do
    current_node_component =
      Locator.get_node_component(graph_component, graph_component.current_node_name)

    stop_timer(current_node_component)

    Ecspanse.Command.update_component!(graph_component,
      is_running: false
    )

    Ecspanse.event(
      {EcspanseStateMachine.Events.GraphStopped,
       [
         graph_entity_id: Ecspanse.Query.get_component_entity(graph_component).id,
         graph_name: graph_component.name,
         graph_reference: graph_component.reference
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
          Components.Graph.t(),
          Components.Node.t(),
          Components.Node.t(),
          atom()
        ) ::
          :ok | {:error, :not_running | :invalid_exit}
  @doc """
  Will transition nodes if the graph is running and the next node is allowed from the current node
  """
  def maybe_transition_nodes(graph_component, current_node_component, next_node_component, reason) do
    if graph_component.is_running and
         current_node_component.name == graph_component.current_node_name do
      is_allowed_exit =
        case current_node_component do
          nil ->
            next_node_component.name == graph_component.starting_node_name

          current_node_component ->
            next_node_component.name in current_node_component.allowed_exit_node_names
        end

      if is_allowed_exit do
        transition_nodes(graph_component, current_node_component, next_node_component, reason)
      else
        {:error, :invalid_exit}
      end
    else
      {:error, :not_running}
    end
  end

  @spec transition_nodes(Components.Graph.t(), Components.Node.t(), Components.Node.t(), atom()) ::
          :ok
  defp transition_nodes(graph_component, current_node_component, next_node_component, reason) do
    unless current_node_component == nil do
      stop_timer(current_node_component)
    end

    Ecspanse.Command.update_component!(graph_component,
      current_node_name: next_node_component.name
    )

    current_node_name =
      case current_node_component do
        nil -> nil
        current_node_component -> current_node_component.name
      end

    graph_entity = Ecspanse.Query.get_component_entity(graph_component)

    Ecspanse.event(
      {EcspanseStateMachine.Events.NodeTransition,
       [
         graph_entity_id: graph_entity.id,
         graph_name: graph_component.name,
         graph_reference: graph_component.reference,
         previous_node_name: current_node_name,
         current_node_name: next_node_component.name,
         reason: reason
       ]}
    )

    start_timer(next_node_component)

    if Enum.empty?(next_node_component.allowed_exit_node_names) do
      stop_graph(graph_component)
    end
  end
end

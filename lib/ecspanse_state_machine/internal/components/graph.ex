defmodule EcspanseStateMachine.Internal.Components.Graph do
  @moduledoc """
  The `container` for a collection of nodes

  ## Fields
  * name: an atom uniquely identifying the graph
  * starting_node_name: the initial node the graph starts in
  * auto_start: the graph is automatically started
  * metadata: data provided by the graph creator that will be passed back in events
  * is_running: true if the graph is running
  * current_node_name: the node name the graph is in
  """
  use Ecspanse.Component,
    state: [
      :name,
      :starting_node_name,
      :metadata,
      :auto_start,
      :is_running,
      :current_node_name
    ],
    tags: [:ecspanse_state_machine_graph]

  def validate(component) do
    with :ok <- validate_name(component),
         :ok <- validate_starting_node_name(component) do
      :ok
    end
  end

  defp validate_name(component) when is_nil(component.name),
    do: {:error, "Graph components must have a name.  #{inspect(component.name)}"}

  defp validate_name(_component), do: :ok

  defp validate_starting_node_name(component) when is_nil(component.starting_node_name),
    do:
      {:error,
       "Graph components must have a starting_node_name.  #{inspect(component.starting_node_name)}"}

  defp validate_starting_node_name(_component), do: :ok
end

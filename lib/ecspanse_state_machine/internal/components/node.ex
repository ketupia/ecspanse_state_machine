defmodule EcspanseStateMachine.Internal.Components.Node do
  @moduledoc """
  A state in the graph

  ## Fields
  * name: an atom uniquely identifying the node
  * allowed_exit_node_names: a list of atoms representing valid target nodes
  * has_timer: a boolean indicating if the node has a timeout timer
  * timeout_node_name: the name of the target node if a timeout occurs
  """
  use Ecspanse.Component,
    state: [
      :name,
      :allowed_exit_node_names,
      :has_timer,
      :timeout_node_name
    ],
    tags: [:ecspanse_state_machine_node]

  def validate(component) do
    validate_name(component)
    validate_timeout(component)
  end

  defp validate_name(component) when is_nil(component.name),
    do: {:error, "State components must have a name.  #{inspect(component.name)}"}

  defp validate_name(_component), do: :ok

  defp validate_timeout(component)
       when component.has_timer and
              is_nil(component.timeout_node_name),
       do: {:error, "A component that has_timer must have a timeout_node_name"}

  defp validate_timeout(component)
       when component.has_timer == false and
              not is_nil(component.timeout_node_name),
       do:
         {:error,
          "A component without a timeout should not have a timeout_node_name, #{inspect(component.timeout_node_name)}"}

  defp validate_timeout(component) when component.has_timer do
    case component.timeout_node_name in component.allowed_exit_node_names do
      true ->
        :ok

      false ->
        {:error,
         "The timeout_node_name, #{component.timeout_node_name}, is not in the list of allowed_transition_states, #{Enum.join(component.allowed_exit_node_names, ", ")}"}
    end
  end

  defp validate_timeout(_component), do: :ok
end

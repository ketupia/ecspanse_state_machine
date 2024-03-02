defmodule EcspanseStateMachine.Internal.Entities.Node do
  @moduledoc """
  entity_spec's for nodes
  """
  alias EcspanseStateMachine.Internal.Components

  @spec blueprint(Ecspanse.Entity.t(), atom(), list(atom)) :: Ecspanse.Entity.entity_spec()
  @doc """
  The entity_spec for a node
  """
  def blueprint(graph_entity, node_name, allowed_exit_node_names) do
    {Ecspanse.Entity,
     components: [
       {Components.Node,
        [name: node_name, allowed_exit_node_names: allowed_exit_node_names, has_timer: false]}
     ],
     parents: [graph_entity]}
  end

  @spec blueprint(Ecspanse.Entity.t(), atom(), list(atom), pos_integer(), atom()) ::
          Ecspanse.Entity.entity_spec()
  @doc """
  The entity_spec for a node with a timeout timer
  """
  def blueprint(graph_entity, node_name, allowed_exit_node_names, duration, timeout_node_name) do
    {Ecspanse.Entity,
     components: [
       {Components.Node,
        [
          name: node_name,
          allowed_exit_node_names: allowed_exit_node_names,
          has_timer: true,
          timeout_node_name: timeout_node_name
        ]},
       {Components.NodeTimeoutTimer, [duration: duration, time: duration]}
     ],
     parents: [graph_entity]}
  end
end

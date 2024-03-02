defmodule EcspanseStateMachine.Entities.Graph do
  @moduledoc """
  entity_spec of a graph
  """
  alias EcspanseStateMachine.Components

  @spec blueprint(atom(), atom()) :: Ecspanse.Entity.entity_spec()
  @doc """
  The entity_spec for a graph
  """
  def blueprint(graph_name, starting_node_name, reference \\ nil),
    do:
      {Ecspanse.Entity,
       components: [
         {Components.Graph,
          [
            name: graph_name,
            starting_node_name: starting_node_name,
            reference: reference,
            is_running: false
          ]}
       ]}
end

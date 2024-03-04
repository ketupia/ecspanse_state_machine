defmodule EcspanseStateMachine.Internal.Entities.Graph do
  @moduledoc """
  entity_spec of a graph
  """
  alias EcspanseStateMachine.Internal.Components

  @spec blueprint(atom(), atom(), boolean(), any()) :: Ecspanse.Entity.entity_spec()
  @doc """
  The entity_spec for a graph
  """
  def blueprint(name, starting_node_name, auto_start, metadata \\ nil),
    do:
      {Ecspanse.Entity,
       components: [
         {Components.Graph,
          [
            name: name,
            starting_node_name: starting_node_name,
            auto_start: auto_start,
            metadata: metadata,
            is_running: false
          ]}
       ]}
end

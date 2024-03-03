defmodule EcspanseStateMachine.Events.GraphStopped do
  @moduledoc """
  Emitted When a graph is stopped

  ## Fields
  * entity_id: the ECSpanse entity id of the graph
  * name: the name of the graph that stopped
  * metadata: the metadata provided when the graph was started
  """
  use Ecspanse.Event, fields: [:entity_id, :name, :metadata]
end

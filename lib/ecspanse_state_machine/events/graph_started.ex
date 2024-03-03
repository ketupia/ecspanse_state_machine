defmodule EcspanseStateMachine.Events.GraphStarted do
  @moduledoc """
  Emitted When a graph starts

  ## Fields
  * entity_id: the ECSpanse entity id of the graph
  * name: the name of the graph that started
  * metadata: the metadata provided when the graph was started
  """
  use Ecspanse.Event, fields: [:entity_id, :name, :metadata]
end

defmodule EcspanseStateMachine.Internal.Events.StopGraphRequest do
  @moduledoc """
  Emitted to stop a running graph.
  The current node's timer will be stopped (if it has one).

  ## Fields
  * graph_name: the name of the graph to stop
  """
  use Ecspanse.Event, fields: [:graph_name]
end

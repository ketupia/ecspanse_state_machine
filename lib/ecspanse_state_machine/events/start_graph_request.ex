defmodule EcspanseStateMachine.Events.StartGraphRequest do
  @moduledoc """
  Emitted to start a graph processing.
  When the graph starts, a transition into the start_node
  will be emitted and that state's timer will be started if it has one.

  ## Fields
  * graph_name: the name of the graph to start
  """
  use Ecspanse.Event, fields: [:graph_name]
end

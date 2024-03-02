defmodule EcspanseStateMachine.Events.GraphStarted do
  @moduledoc """
  Emitted When a graph starts

  ## Fields
  * graph_name: the name of the graph that started
  """
  use Ecspanse.Event, fields: [:graph_name, :graph_reference]
end

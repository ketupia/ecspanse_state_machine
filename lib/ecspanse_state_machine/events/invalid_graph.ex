defmodule EcspanseStateMachine.Events.InvalidGraph do
  @moduledoc """
  Emitted When a graph validation fails.  The graph is validated when it is started.

  ## Fields
  * graph_name: the name of the graph that started
  * reason: the reason for the graph is invalid
  """
  use Ecspanse.Event, fields: [:graph_name, :graph_reference, :reason]
end

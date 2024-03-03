defmodule EcspanseStateMachine.Internal.Systems.OnStopGraphRequest do
  @moduledoc """
  Stops the graph if it's running
  """
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.Engine

  use Ecspanse.System, event_subscriptions: [Events.StopGraphRequest]

  def run(%Events.StopGraphRequest{graph_entity_id: graph_entity_id}, _frame) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      Engine.maybe_stop_graph(graph_entity)
    end
  end
end

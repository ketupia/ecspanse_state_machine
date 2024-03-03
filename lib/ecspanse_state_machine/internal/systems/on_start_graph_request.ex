defmodule EcspanseStateMachine.Internal.Systems.OnStartGraphRequest do
  @moduledoc """
  Starts the graph unless it is already running
  """
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.Engine

  use Ecspanse.System, event_subscriptions: [Events.StartGraphRequest]

  def run(%Events.StartGraphRequest{graph_entity_id: graph_entity_id}, _frame) do
    with {:ok, graph_entity} <- Ecspanse.Entity.fetch(graph_entity_id) do
      Engine.maybe_start_graph(graph_entity)
    end
  end
end

defmodule EcspanseStateMachine.Internal.Systems.OnStartGraphRequest do
  @moduledoc """
  Starts the graph unless it is already running
  """
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Engine

  use Ecspanse.System, event_subscriptions: [Events.StartGraphRequest]

  def run(%Events.StartGraphRequest{graph_name: graph_name}, _frame) do
    with {:ok, graph_component} <- Locator.fetch_graph_component_by_name(graph_name) do
      Engine.maybe_start_graph(graph_component)
    end
  end
end

defmodule EcspanseStateMachine.Internal.Systems.OnStopGraphRequest do
  @moduledoc """
  Stops the graph if it's running
  """
  alias EcspanseStateMachine.Internal.Events
  alias EcspanseStateMachine.Internal.Locator
  alias EcspanseStateMachine.Internal.Engine

  use Ecspanse.System, event_subscriptions: [Events.StopGraphRequest]

  def run(%Events.StopGraphRequest{graph_name: graph_name}, _frame) do
    with {:ok, graph_component} <- Locator.fetch_graph_component_by_name(graph_name) do
      Engine.maybe_stop_graph(graph_component)
    end
  end
end

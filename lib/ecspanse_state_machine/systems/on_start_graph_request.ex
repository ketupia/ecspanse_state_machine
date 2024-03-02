defmodule EcspanseStateMachine.Systems.OnStartGraphRequest do
  @moduledoc """
  Starts the graph unless it is already running
  """
  alias EcspanseStateMachine.Events
  alias EcspanseStateMachine.Internals.Locator
  alias EcspanseStateMachine.Internals.Engine

  use Ecspanse.System, event_subscriptions: [Events.StartGraphRequest]

  def run(%Events.StartGraphRequest{graph_name: graph_name}, _frame) do
    with {:ok, graph_component} <- Locator.fetch_graph_component_by_name(graph_name) do
      Engine.maybe_start_graph(graph_component)
    end
  end
end

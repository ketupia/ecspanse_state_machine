defmodule EcspanseStateMachine.Internal.Systems.OnStateChanged do
  @moduledoc """
  Starts/Stops the Timeout Timer on state change
  """
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Events
  require Logger

  use Ecspanse.System, event_subscriptions: [Events.StateChanged]

  def run(
        %Events.StateChanged{entity_id: entity_id, to: to},
        _frame
      ) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, timer} <- Components.StateTimer.fetch(entity) do
      update_timer(timer, to)
    else
      _ -> :ok
    end
  end

  defp update_timer(timer, to) do
    changes = [paused: true]

    changes =
      case {to, Components.StateTimer.get_timeout(timer, to)} do
        {nil, _} ->
          changes

        {_to, nil} ->
          changes

        {to, timeout} ->
          changes
          |> Keyword.put(:paused, false)
          |> Keyword.put(:duration, timeout[:duration])
          |> Keyword.put(:time, timeout[:duration])
          |> Keyword.put(:timing_state, to)
      end

    Ecspanse.Command.update_component!(timer, changes)

    # Logger.info(
    #   "Timer changes for #{Ecspanse.Query.get_component_entity(timer).id}: #{inspect(changes)}"
    # )
  end
end

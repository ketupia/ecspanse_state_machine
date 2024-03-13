defmodule EcspanseStateMachine.Internal.Systems.AutoStarter do
  @moduledoc false
  # Starts the machine unless it is already running

  alias EcspanseStateMachine.Components

  use Ecspanse.System

  def run(_frame) do
    Components.StateMachine.list()
    |> Enum.filter(& &1.auto_start)
    |> Enum.each(fn sm ->
      Ecspanse.Command.update_component!(sm, auto_start: false)
      EcspanseStateMachine.request_start(Ecspanse.Query.get_component_entity(sm).id)
    end)
  end
end

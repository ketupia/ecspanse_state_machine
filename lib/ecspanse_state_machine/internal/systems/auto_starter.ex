defmodule EcspanseStateMachine.Internal.Systems.AutoStarter do
  @moduledoc false
  # Starts the machine unless it is already running

  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Components

  use Ecspanse.System

  def run(_frame) do
    Components.StateMachine.list()
    |> Enum.filter(& &1.auto_start)
    |> Enum.each(fn state_machine ->
      Ecspanse.Command.update_component!(state_machine, auto_start: false)
      Engine.start(state_machine)
    end)
  end
end

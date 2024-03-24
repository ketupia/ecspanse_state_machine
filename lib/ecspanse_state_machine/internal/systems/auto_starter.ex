defmodule EcspanseStateMachine.Internal.Systems.AutoStarter do
  @moduledoc false
  # Starts the machine unless it is already running

  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Components

  use Ecspanse.System

  def run(_frame) do
    Components.StateMachine.list()
    |> Enum.filter(& &1.auto_start)
    |> Enum.each(&Engine.start(&1))
  end
end

defmodule EcspanseStateMachine.Manager do
  @moduledoc """
  Call `setup` to configure the state machine systems.
  """
  alias EcspanseStateMachine.Systems
  use Ecspanse

  @impl Ecspanse
  def setup(data) do
    data
    #
    # system startup
    #
    # |> Ecspanse.add_startup_system(Ecspanse.System.Timer)

    #
    # frame start
    #
    |> Ecspanse.add_frame_start_system(Systems.OnNodeTimeout)
    |> Ecspanse.add_frame_start_system(Systems.OnNodeTransitionRequest)
    |> Ecspanse.add_frame_start_system(Systems.OnStartGraphRequest)

    #
    # every frame
    #
    #
    # frame end
    #
  end
end

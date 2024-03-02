defmodule EcspanseStateMachine.Manager do
  @moduledoc """
  Call `setup` to configure the state machine systems.
  """
  alias EcspanseStateMachine.Internal.Systems
  use Ecspanse

  @impl Ecspanse
  def setup(data) do
    data
    #
    # system startup
    #

    #
    # frame start
    #
    |> Ecspanse.add_frame_start_system(Systems.OnNodeTimeout)
    |> Ecspanse.add_frame_start_system(Systems.OnNodeTransitionRequest)
    |> Ecspanse.add_frame_start_system(Systems.OnStartGraphRequest)
    |> Ecspanse.add_frame_start_system(Systems.OnStopGraphRequest)

    #
    # every frame
    #
    #
    # frame end
    #
  end
end

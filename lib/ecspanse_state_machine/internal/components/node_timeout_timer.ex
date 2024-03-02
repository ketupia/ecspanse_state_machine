defmodule EcspanseStateMachine.Internal.Components.NodeTimeoutTimer do
  @moduledoc """
  The timer component for nodes that have a timeout
  """
  alias EcspanseStateMachine.Internal.Events

  use Ecspanse.Template.Component.Timer,
    state: [
      duration: 5_000,
      time: 5_000,
      event: Events.NodeTimeout,
      mode: :once,
      paused: true
    ],
    tags: [:ecspanse_state_machine_node_timeout_timer]
end

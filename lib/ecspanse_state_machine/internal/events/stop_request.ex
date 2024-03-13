defmodule EcspanseStateMachine.Internal.Events.StopRequest do
  @moduledoc false
  # Emitted to stop a machine.

  use Ecspanse.Event, fields: [:entity_id]
end

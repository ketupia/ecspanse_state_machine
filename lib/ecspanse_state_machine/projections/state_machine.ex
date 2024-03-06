defmodule EcspanseStateMachine.Projections.StateMachine do
  @moduledoc """
  The projection for a state_machine component
  """
  alias EcspanseStateMachine.Components

  use Ecspanse.Projection,
    fields: [
      :initial_state,
      :auto_start,
      :is_running,
      :current_state
    ]

  @impl true
  def project(%{entity_id: entity_id} = _attrs) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      fields =
        [
          {:initial_state, state_machine.initial_state},
          {:auto_start, state_machine.auto_start},
          {:is_running, state_machine.is_running},
          {:current_state, state_machine.current_state}
        ]

      {:ok, struct!(__MODULE__, fields)}
    else
      _ -> :error
    end
  end
end

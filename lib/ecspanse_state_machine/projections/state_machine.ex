defmodule EcspanseStateMachine.Projections.StateMachine do
  @moduledoc """
  The projection for a state_machine component
  """
  alias EcspanseStateMachine.Components.StateMachine
  alias EcspanseStateMachine.Components

  use Ecspanse.Projection,
    fields: [
      :entity_id,
      :initial_state,
      :auto_start,
      :is_running,
      :current_state
    ]

  @impl true
  def project(%{entity_id: entity_id} = _attrs) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      project(state_machine)
    else
      _ -> :error
    end
  end

  def project(%StateMachine{} = state_machine) do
    fields =
      [
        {:entity_id, Ecspanse.Query.get_component_entity(state_machine).id},
        {:initial_state, state_machine.initial_state},
        {:auto_start, state_machine.auto_start},
        {:is_running, state_machine.is_running},
        {:current_state, state_machine.current_state}
      ]

    {:ok, struct!(__MODULE__, fields)}
  end
end

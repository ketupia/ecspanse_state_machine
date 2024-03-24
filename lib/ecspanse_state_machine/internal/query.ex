defmodule EcspanseStateMachine.Internal.Query do
  @moduledoc false
  # Common queries

  alias EcspanseStateMachine.Components

  @spec fetch_state_machine(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          {:error, :not_found} | {:ok, struct()}
  def fetch_state_machine(%Ecspanse.Entity{} = entity) do
    Components.StateMachine.fetch(entity)
  end

  def fetch_state_machine(entity_id) when is_binary(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id) do
      fetch_state_machine(entity)
    end
  end
end

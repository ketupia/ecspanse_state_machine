defmodule EcspanseStateMachine.Internal.Projector do
  @moduledoc false
  alias EcspanseStateMachine.Internal.StateSpec
  alias EcspanseStateMachine.Components

  @doc """
  Returns a map of the state_machine to use in your projections
  """
  def project(%Components.StateMachine{} = state_machine) do
    {time, default_exit} =
      case state_machine.paused do
        true ->
          {0, nil}

        _ ->
          {state_machine.time,
           Components.StateMachine.get_state_spec(state_machine, state_machine.current_state)
           |> StateSpec.default_exit()}
      end

    timer = %{
      paused: state_machine.paused,
      time: time,
      duration: state_machine.duration,
      exits_to: default_exit
    }

    {:ok,
     %{
       entity_id: Ecspanse.Query.get_component_entity(state_machine).id,
       initial_state: state_machine.initial_state,
       auto_start: state_machine.auto_start,
       running?: state_machine.running?,
       current_state: state_machine.current_state,
       timer: timer
     }}
  end
end

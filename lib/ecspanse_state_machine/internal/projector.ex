defmodule EcspanseStateMachine.Internal.Projector do
  @moduledoc false
  alias EcspanseStateMachine.Internal.StateSpec
  alias EcspanseStateMachine.Components

  @doc """
  Returns a map of the state_machine to use in your projections
  """
  def project(%Components.StateMachine{} = state_machine) do
    default_exit =
      case state_machine.timing_state do
        nil ->
          nil

        _ ->
          Components.StateMachine.get_state_spec(state_machine, state_machine.timing_state)
          |> StateSpec.default_exit()
      end

    timer = %{
      timing_state: state_machine.timing_state,
      paused: state_machine.paused,
      time: state_machine.time,
      duration: state_machine.duration,
      exits_to: default_exit
    }

    {:ok,
     %{
       entity_id: Ecspanse.Query.get_component_entity(state_machine).id,
       initial_state: state_machine.initial_state,
       auto_start: state_machine.auto_start,
       is_running: state_machine.is_running,
       current_state: state_machine.current_state,
       timer: timer
     }}
  end
end

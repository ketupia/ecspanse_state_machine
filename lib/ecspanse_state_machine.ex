defmodule EcspanseStateMachine do
  @moduledoc """
  `EcspanseStateMachine`.
  """
  alias EcspanseStateMachine.Projections
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Internal

  @spec as_mermaid_diagram(Ecspanse.Entity.id()) ::
          {:ok, String.t()} | {:error, :not_found}
  @doc """
  Generates the source for a Mermaid State Diagram
  """
  def as_mermaid_diagram(entity_id, title \\ "") do
    Internal.Mermaid.as_state_diagram(entity_id, title)
  end

  @spec change_state(
          Ecspanse.Entity.id(),
          atom() | String.t(),
          atom() | String.t(),
          atom() | String.t()
        ) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to change state
  """
  def change_state(entity_id, from, to, trigger \\ :request) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, _state_machine} <- Components.StateMachine.fetch(entity) do
      Ecspanse.event(
        {Internal.Events.ChangeStateRequest,
         [
           entity_id: entity_id,
           from: from,
           to: to,
           trigger: trigger
         ]}
      )
    end
  end

  @spec fetch_states(Ecspanse.Entity.id()) :: {:ok, list()} | {:error, :not_found}
  @doc """
  Returns a list of state names
  """
  def fetch_states(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      states = state_machine.states |> Enum.map(& &1[:name])
      {:ok, states}
    end
  end

  @spec fetch_state_exits_to(Ecspanse.Entity.id(), atom() | String.t()) ::
          {:ok, list()} | {:error, :not_found}
  @doc """
  Returns the exits_to states for the named state
  """
  def fetch_state_exits_to(entity_id, name) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      case Components.StateMachine.get_exits_to(state_machine, name) do
        nil -> {:error, :not_found}
        exits_to -> {:ok, exits_to}
      end
    end
  end

  @doc """
  setup is to be called when registering ECSpanse systems in your manager
  """
  @spec setup(Ecspanse.Data.t()) :: Ecspanse.Data.t()
  def setup(data) do
    data
    |> Ecspanse.add_frame_start_system(Internal.Systems.AutoStarter)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnChangeStateRequest)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStartRequest)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStopRequest)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStateChanged)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStopped)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStateTimeout)
  end

  @spec start(Ecspanse.Entity.id()) ::
          :ok | {:error, :not_found}
  @doc """
  Starts a state machine
  """
  def start(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, _state_machine} <- Components.StateMachine.fetch(entity) do
      Ecspanse.event({Internal.Events.StartRequest, [entity_id: entity_id]})
    end
  end

  @spec state_machine(atom() | String.t(), list(Keyword.t()), boolean()) ::
          Ecspanse.Component.component_spec()
  @doc """
  Creates and returns a component_spec for a State Machine
  """
  def state_machine(initial_state, states, auto_start \\ true) do
    {Components.StateMachine,
     [initial_state: initial_state, states: states, auto_start: auto_start]}
  end

  @spec state_timer(list(Keyword.t())) ::
          Ecspanse.Component.component_spec()
  @doc """
  Creates and returns a component_spec for a State Timer
  """
  def state_timer(timeouts) do
    {Components.StateTimer, [timeouts: timeouts]}
  end

  @spec stop(Ecspanse.Entity.id()) ::
          :ok | {:error, :not_found}
  @doc """
  Stops a state machine
  """
  def stop(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, _state_machine} <- Components.StateMachine.fetch(entity) do
      Ecspanse.event({Internal.Events.StopRequest, [entity_id: entity_id]})
    end
  end

  # @spec project(Ecspanse.Entity.id()) ::
  #         {:ok, {Projections.StateMachine.project(t(), Projections.State} | {:error, :not_found}
  @doc """
  Returns a projection of the state machine
  """
  def project(entity_id) when is_binary(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id) do
      project(entity)
    end
  end

  def project(entity) do
    state_machine_projection =
      case Projections.StateMachine.project(%{entity_id: entity.id}) do
        {:ok, projection} -> projection
        _ -> nil
      end

    state_timer_projection =
      case Projections.StateTimer.project(%{entity_id: entity.id}) do
        {:ok, projection} -> projection
        _ -> nil
      end

    {state_machine_projection, state_timer_projection}
  end
end

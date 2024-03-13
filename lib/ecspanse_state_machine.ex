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

  ## Parameters
    - title: The diagram will have this title (optional)
  """
  def as_mermaid_diagram(entity_id, title \\ "") do
    Internal.Mermaid.as_state_diagram(entity_id, title)
  end

  @spec request_transition(
          Ecspanse.Entity.id(),
          atom() | String.t(),
          atom() | String.t(),
          atom() | String.t()
        ) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to transition from one state to another.

  This will trigger a state change so long as
  * the state machine is running
  * the from state is the machines's current state
  * the to state is valid from the current state

  ## Parameters
    - from: the state to transition from
    - to: the state to transition to
    - trigger: the reason for the transition
  """
  def request_transition(entity_id, from, to, trigger \\ :request) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, _state_machine} <- Components.StateMachine.fetch(entity) do
      Ecspanse.event(
        {Internal.Events.TransitionRequest,
         [
           entity_id: entity_id,
           from: from,
           to: to,
           trigger: trigger
         ]}
      )
    end
  end

  @spec fetch_current(Ecspanse.Entity.id()) ::
          {:ok, atom() | String.t()} | {:error, :not_found} | {:error, :not_running}
  @doc """
  Returns the current state of the state machine
  """
  def fetch_current(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      if state_machine.is_running do
        {:ok, state_machine.current_state}
      else
        {:error, :not_running}
      end
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
  setup is to be called when registering ECSpanse systems in your manager.

  ## Examples
      def setup(data) do
        data
        |> EcspanseStateMachine.setup()
        #
        # Your registrations here
        #
        # Be sure to setup the Ecspanse.System.Timer if you have any timeouts
        |> Ecspanse.add_frame_end_system(Ecspanse.System.Timer)
      end
  """
  @spec setup(Ecspanse.Data.t()) :: Ecspanse.Data.t()
  def setup(data) do
    data
    |> Ecspanse.add_frame_start_system(Internal.Systems.AutoStarter)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStartRequest)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStopRequest)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStateChanged)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStopped)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStateTimeout)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnTransitionRequest)
  end

  @spec request_start(Ecspanse.Entity.id()) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to start a state machine
  """
  def request_start(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, _state_machine} <- Components.StateMachine.fetch(entity) do
      Ecspanse.event({Internal.Events.StartRequest, [entity_id: entity_id]})
    end
  end

  @spec state_machine(atom() | String.t(), list(Keyword.t()), Keyword.t()) ::
          Ecspanse.Component.component_spec()
  @doc """
  Creates a component_spec for a State Machine

  ## Options
    auto_start: boolean - if true, the state machine will start automatically

  ## Examples
      traffic_light_component_spec =
        EcspanseStateMachine.state_machine(:red, [
          [name: :red, exits_to: [:green, :flashing_red]],
          [name: :flashing_red, exits_to: [:red]],
         [name: :green, exits_to: [:yellow]],
         [name: :yellow, exits_to: [:red]]
        ])
  """
  def state_machine(initial_state, states, opts \\ [auto_start: true]) do
    {Components.StateMachine,
     [
       initial_state: initial_state,
       states: states,
       auto_start: Keyword.get(opts, :auto_start, true)
     ]}
  end

  @spec state_timer(list(Keyword.t())) ::
          Ecspanse.Component.component_spec()
  @doc """
  Creates a component_spec for a State Timer
  """
  def state_timer(timeouts) do
    {Components.StateTimer, [timeouts: timeouts]}
  end

  @spec request_stop(Ecspanse.Entity.id()) ::
          :ok | {:error, :not_found}
  @doc """
  Submits a request to stop a state machine
  """
  def request_stop(entity_id) do
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

defmodule EcspanseStateMachine do
  @moduledoc """
  ECSpanse State Machine Api
  """
  alias EcspanseStateMachine.Components
  alias EcspanseStateMachine.Internal.Engine
  alias EcspanseStateMachine.Internal.Mermaid
  alias EcspanseStateMachine.Internal.Projector
  alias EcspanseStateMachine.Internal.Systems

  @type state_name :: atom() | String.t()

  @spec format_as_mermaid_diagram(Ecspanse.Entity.id(), String.t()) ::
          {:ok, String.t()} | {:error, :not_found}
  @doc """
  Generates the source for a [Mermaid State Diagram](https://mermaid.js.org)

  ## Parameters
    - title: The diagram will have this title (optional)
  """
  def format_as_mermaid_diagram(entity_id, title \\ "") do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      Mermaid.as_state_diagram(state_machine, title)
    end
  end

  @spec new(state_name(), list(Keyword.t()), Keyword.t()) ::
          Ecspanse.Component.component_spec()
  @doc """
  Creates a [component_spec](https://hexdocs.pm/ecspanse/Ecspanse.Component.html#t:component_spec/0) for a State Machine

  ## Options
    auto_start: boolean - if true, the state machine will start automatically

  ## Examples
      state_machine =
        EcspanseStateMachine.new(:red, [
          [name: :red, exits: [:green, :flashing_red], timeout: 30_000],
          [name: :flashing_red, exits: [:red]],
          [name: :green, exits: [:yellow], timeout: 10_000, default_exit: :yellow],
          [name: :yellow, exits: [:red]]
        ])
  """
  def new(initial_state, states, opts \\ []) do
    {Components.StateMachine,
     [
       initial_state: initial_state,
       states: states,
       auto_start: Keyword.get(opts, :auto_start, true)
     ]}
  end

  @doc """
  Returns a map of the state_machine to use in your [projections](https://hexdocs.pm/ecspanse/Ecspanse.Projection.html).
  """
  def project(entity_id) when is_binary(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      Projector.project(state_machine)
    end
  end

  @doc """
  Registers the state machine systems with the ECSpanse manager.

  Call this from your setup(data) function. [See ECSpanse Setup](https://hexdocs.pm/ecspanse/getting_started.html#setup)

  ## Examples
      def setup(data) do
        data
        |> EcspanseStateMachine.setup()
        #
        # Your registrations here
        #
        # Be sure to setup the Ecspanse.System.Timer if you have any 73s
        |> Ecspanse.add_frame_end_system(Ecspanse.System.Timer)
      end
  """
  @spec setup(Ecspanse.Data.t()) :: Ecspanse.Data.t()
  def setup(data) do
    data
    |> Ecspanse.add_frame_start_system(Systems.AutoStarter)
    |> Ecspanse.add_frame_start_system(Systems.OnStateTimeout)
  end

  @spec start(Ecspanse.Entity.id()) :: :ok | {:error, :already_running} | {:error, :not_found}
  @doc """
  Starts the state machine
  """
  def start(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      Engine.start(state_machine)
    end
  end

  @spec stop(Ecspanse.Entity.id()) :: :ok | {:error, :not_running} | {:error, :not_found}
  @doc """
  Stops a state machine
  """
  def stop(entity_id) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      Engine.stop(state_machine)
    end
  end

  @spec transition(Ecspanse.Entity.id(), state_name(), state_name(), any()) ::
          :ok | {:error, :not_found}
  @doc """
  Triggers a state change

  * the state machine is needs to be running
  * the from state must be the current state
  * the to state must be in the current state's exits

  ## Parameters
    - from: the state to transition from
    - to: the state to transition to
    - trigger: the reason for the transition
  """
  def transition(entity_id, from, to, trigger \\ :request) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      Engine.transition(state_machine, from, to, trigger)
    end
  end

  @spec transition_to_default_exit(Ecspanse.Entity.id(), state_name(), any) ::
          :ok | {:error, :not_found}
  @doc """
  Triggers a state change to the default exit

  * the state machine is needs to be running
  * the from state must be the current state
  * the from state must have an exit

  ## Parameters
    - from: the state to transition from
    - trigger: the reason for the transition
  """
  def transition_to_default_exit(entity_id, from, trigger \\ :request) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, state_machine} <- Components.StateMachine.fetch(entity) do
      Engine.transition_to_default_exit(state_machine, from, trigger)
    end
  end
end

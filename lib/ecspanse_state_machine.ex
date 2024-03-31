defmodule EcspanseStateMachine do
  @moduledoc """
  ECSpanse State Machine Api
  """
  alias EcspanseStateMachine.Internal
  alias EcspanseStateMachine.Components
  use EcspanseStateMachine.Types

  @doc """
  Retrieves the current state of the state machine in the given entity if it is running.
  """
  @spec current_state(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          {:ok, state_name()} | {:error, :not_found} | {:error, :not_running}
  def current_state(entity_id_or_entity) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      Internal.Engine.current_state(state_machine)
    end
  end

  @doc """
  Generates the source for a [Mermaid State Diagram](https://mermaid.js.org)

  ## Parameters
    - title: The diagram will have this title (optional)
  """
  @spec format_as_mermaid_diagram(Ecspanse.Entity.id() | Ecspanse.Entity.t(), String.t()) ::
          {:ok, String.t()} | {:error, :not_found}
  def format_as_mermaid_diagram(entity_id_or_entity, title \\ "") do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      Internal.Mermaid.as_state_diagram(state_machine, title)
    end
  end

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
  @spec new(state_name(), list(Keyword.t()), Keyword.t()) ::
          Ecspanse.Component.component_spec()
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
  @spec project(Ecspanse.Entity.id() | Ecspanse.Entity.t()) :: {:ok, map()} | {:error, :not_found}
  def project(entity_id_or_entity) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      Internal.Projector.project(state_machine)
    end
  end

  @doc """
  Returns true/false if the state machine is running
  """
  @spec running?(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          {:ok, boolean()} | {:error, :not_found}
  def running?(entity_id_or_entity) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      {:ok, state_machine.running?}
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
    |> Ecspanse.add_frame_start_system(Internal.Systems.AutoStarter)
    |> Ecspanse.add_frame_start_system(Internal.Systems.OnStateTimeout)
  end

  @doc """
  Starts the state machine
  """
  @spec start(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          :ok | {:error, :already_running} | {:error, :not_found}
  def start(entity_id_or_entity) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      Internal.Engine.start(state_machine)
    end
  end

  @doc """
  Stops the state machine
  """
  @spec stop(Ecspanse.Entity.id() | Ecspanse.Entity.t()) ::
          :ok | {:error, :already_running} | {:error, :not_found}
  def stop(entity_id_or_entity) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      Internal.Engine.stop(state_machine)
    end
  end

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
  @spec transition(Ecspanse.Entity.id() | Ecspanse.Entity.t(), state_name(), state_name(), any()) ::
          :ok | {:error, :not_found}
  def transition(entity_id_or_entity, from, to, trigger \\ :request) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      Internal.Engine.transition(state_machine, from, to, trigger)
    end
  end

  @doc """
  Triggers a state change to the default exit

  * the state machine is needs to be running
  * the from state must be the current state
  * the from state must have an exit

  ## Parameters
    - from: the state to transition from
    - trigger: the reason for the transition
  """
  @spec transition_to_default_exit(Ecspanse.Entity.id() | Ecspanse.Entity.t(), state_name(), any) ::
          :ok | {:error, :not_found}
  def transition_to_default_exit(entity_id_or_entity, from, trigger \\ :request) do
    with {:ok, state_machine} <- Internal.Query.fetch_state_machine(entity_id_or_entity) do
      Internal.Engine.transition_to_default_exit(state_machine, from, trigger)
    end
  end
end

defmodule Lux.Agent.Companies.SignalHandler do
  @moduledoc """
  Behaviour module that defines how company agents should handle different types of signals.

  This module defines callbacks for:
  1. Task-related signals (assignments, updates, completion)
  2. Plan-related signals (evaluation, next steps)
  3. General signal handling
  """

  alias Lux.Schemas.Companies.PlanSignal
  alias Lux.Schemas.Companies.TaskSignal
  alias Lux.Signal

  @doc """
  Called when a signal is received by the agent.
  Should dispatch to appropriate handler based on signal schema.
  """
  @callback handle_signal(Signal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called when a task is assigned to the agent.
  Should evaluate the task and determine how to complete it.
  """
  @callback handle_task_assignment(TaskSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called to update task progress.
  Should evaluate current state and send progress update.
  """
  @callback handle_task_update(TaskSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called when a task is completed.
  Should validate completion and prepare completion report.
  """
  @callback handle_task_completion(TaskSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called when a task fails.
  Should prepare failure report with reason and any recovery steps.
  """
  @callback handle_task_failure(TaskSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called for CEO agents to evaluate plan progress.
  Should assess current state and decide next actions.
  """
  @callback handle_plan_evaluation(PlanSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called for CEO agents to determine next step in plan.
  Should analyze dependencies and assign appropriate agent.
  """
  @callback handle_plan_next_step(PlanSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called to update plan status.
  Should evaluate progress and update plan metadata.
  """
  @callback handle_plan_update(PlanSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @doc """
  Called when a plan is completed.
  Should validate all steps are complete and prepare completion report.
  """
  @callback handle_plan_completion(PlanSignal.t(), context :: map()) ::
              {:ok, Signal.t()} | {:error, term()}

  @optional_callbacks [
    handle_task_assignment: 2,
    handle_task_update: 2,
    handle_task_completion: 2,
    handle_task_failure: 2,
    handle_plan_evaluation: 2,
    handle_plan_next_step: 2,
    handle_plan_update: 2,
    handle_plan_completion: 2
  ]

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Lux.Agent.Companies.SignalHandler

      # Default implementation of base signal handler
      @impl true
      def handle_signal(%Signal{schema_id: schema_id} = signal, context) do
        case schema_id do
          TaskSignal ->
            handle_task_signal(signal, context)

          PlanSignal ->
            handle_plan_signal(signal, context)

          _ ->
            {:error, :unsupported_schema}
        end
      end

      defp handle_task_signal(%Signal{payload: %{"type" => type}} = signal, context) do
        case type do
          "assignment" -> handle_task_assignment(signal, context)
          "status_update" -> handle_task_update(signal, context)
          "completion" -> handle_task_completion(signal, context)
          "failure" -> handle_task_failure(signal, context)
          _ -> {:error, :unsupported_task_type}
        end
      end

      defp handle_plan_signal(%Signal{payload: %{"type" => type}} = signal, context) do
        case type do
          "evaluate" -> handle_plan_evaluation(signal, context)
          "next_step" -> handle_plan_next_step(signal, context)
          "status_update" -> handle_plan_update(signal, context)
          "completion" -> handle_plan_completion(signal, context)
          _ -> {:error, :unsupported_plan_type}
        end
      end

      # Default implementations that return :not_implemented
      def handle_task_assignment(_, _), do: {:error, :not_implemented}
      def handle_task_update(_, _), do: {:error, :not_implemented}
      def handle_task_completion(_, _), do: {:error, :not_implemented}
      def handle_task_failure(_, _), do: {:error, :not_implemented}
      def handle_plan_evaluation(_, _), do: {:error, :not_implemented}
      def handle_plan_next_step(_, _), do: {:error, :not_implemented}
      def handle_plan_update(_, _), do: {:error, :not_implemented}
      def handle_plan_completion(_, _), do: {:error, :not_implemented}

      # Allow overriding any of these functions
      defoverridable handle_signal: 2,
                     handle_task_assignment: 2,
                     handle_task_update: 2,
                     handle_task_completion: 2,
                     handle_task_failure: 2,
                     handle_plan_evaluation: 2,
                     handle_plan_next_step: 2,
                     handle_plan_update: 2,
                     handle_plan_completion: 2
    end
  end
end

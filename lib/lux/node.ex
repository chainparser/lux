defmodule Lux.Node do
  @moduledoc """
  Provides functions for executing Node.js code with variable bindings.

  The ~JS sigil is used to write Node.js code directly in Elixir files.
  In the Node.js code, you have to export a function named `main` that takes
  an object as an argument and returns a value.

      export const main = ({x, y}) => x + y

  ## Examples

      iex> require Lux.Node
      iex> Lux.Node.nodejs variables: %{x: 40, y: 2} do
      ...>   ~JS'''
      ...>   export const main = ({x, y}) => x + y
      ...>   '''
      ...> end
      42
  """
  @type eval_option ::
          {:variables, map()}
          | {:timeout, pos_integer()}

  @type eval_options :: [eval_option()]

  @module_path Application.app_dir(:lux, "priv/node")

  @doc """
  Evaluates Node.js code with optional variable bindings and other options.

  ## Options

    * `:variables` - A map of variables to bind in the Node.js context
    * `:timeout` - Timeout in milliseconds for Node.js execution

  ## Examples

      iex> Lux.Node.eval("export const main = ({x}) => x * 2", variables: %{x: 21})
      {:ok, 42}

      iex> Lux.Node.eval("export const main = () => os.getenv('TEST')", env: %{"TEST" => "value"})
      {:ok, "value"}
  """
  @spec eval(String.t(), eval_options()) :: {:ok, term()} | {:error, String.t()}
  def eval(code, opts \\ []) do
    {variables, opts} = Keyword.pop(opts, :variables, %{})
    do_eval(code, variables, opts, &NodeJS.call/3)
  end

  @doc """
  Same as `eval/2`, but raises an error.
  """
  def eval!(code, opts \\ []) do
    {variables, opts} = Keyword.pop(opts, :variables, %{})
    do_eval(code, variables, opts, &NodeJS.call!/3)
  end

  @doc """
  Returns a module path for the Node.js.
  """
  @spec module_path() :: String.t()
  def module_path, do: @module_path

  @spec child_spec(keyword()) :: :supervisor.child_spec()
  def child_spec(opts \\ []) do
    NodeJS.Supervisor.child_spec([path: module_path()] ++ opts)
  end

  @doc """
  Attempts to import a Node.js package.
  """
  @spec import_package(String.t(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def import_package(package_name, _opts \\ []) when is_binary(package_name) do
    # TBD
    {:ok, package_name}
  end

  @doc """
  A macro for executing Node.js code with variable bindings.
  Node.js code should be wrapped in a sigil ~JS to bypass Elixir syntax checking.
  """
  defmacro nodejs(opts \\ [], do: {:sigil_JS, _, [{:<<>>, _, [code]}, []]}) do
    quote do
      Lux.Node.eval(unquote(code), unquote(opts))
    end
  end

  @doc false
  defmacro sigil_JS({:<<>>, _meta, [string]}, _modifiers) do
    quote do: unquote(string)
  end

  defp do_eval(code, variables, opts, fun) do
    filename = create_file_name(code)

    with {:ok, node_modules_path} <- maybe_create_node_modules(),
         file_path = Path.join(node_modules_path, filename),
         :ok <- File.write(file_path, code) do
      fun.({file_path, "main"}, [variables], opts)
    else
      error -> error
    end
  end

  defp maybe_create_node_modules do
    node_modules = Path.join(@module_path, "node_modules/lux")

    unless File.exists?(node_modules) do
      File.mkdir_p(node_modules)
    end

    {:ok, node_modules}
  end

  defp create_file_name(code) do
    hash = :crypto.hash(:sha, code) |> Base.encode16(case: :lower)
    "#{hash}.mjs"
  end
end

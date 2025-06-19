defmodule Explorer.SmartContract.Huff.Verifier do
  @moduledoc """
  Verifies Huff contracts by compiling and comparing bytecode.
  """

  alias Explorer.SmartContract.Huff.CodeCompiler

  import Explorer.SmartContract.Helper,
    only: [contract_creation_input: 1]

  def evaluate_authenticity(_, %{"contract_source_code" => ""}),
    do: {:error, :contract_source_code}

  def evaluate_authenticity(address_hash, params) do
    contract_source_code = Map.fetch!(params, "contract_source_code")
    compiler_version = Map.fetch!(params, "compiler_version")
    constructor_arguments = Map.get(params, "constructor_arguments", "")

    output =
      CodeCompiler.run(
        compiler_version: compiler_version,
        code: contract_source_code
      )

    compare_bytecodes(output, address_hash, constructor_arguments)
  end

  defp compare_bytecodes({:error, _}, _, _), do: {:error, :compilation}

  defp compare_bytecodes({:ok, %{"bytecode" => bytecode}}, address_hash, args) do
    blockchain_bytecode =
      address_hash
      |> contract_creation_input()
      |> String.trim()

    if String.trim(bytecode <> args) == blockchain_bytecode do
      {:ok, %{abi: []}}
    else
      {:error, :generated_bytecode}
    end
  end
end

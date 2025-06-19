defmodule Explorer.SmartContract.Huff.Publisher do
  @moduledoc """
  Handles Huff smart contract verification and publishing.
  """

  require Logger

  alias Explorer.Chain.SmartContract
  alias Explorer.SmartContract.Huff.Verifier
  alias Explorer.SmartContract.CompilerVersion
  import Explorer.SmartContract.Helper, only: [prepare_license_type: 1]

  def publish(address_hash, params) do
    case Verifier.evaluate_authenticity(address_hash, params) do
      {:ok, %{abi: abi}} ->
        publish_smart_contract(address_hash, params, abi)

      {:error, error} ->
        {:error, unverified_smart_contract(address_hash, params, error, nil)}
    end
  end

  defp publish_smart_contract(address_hash, params, abi) do
    attrs = attributes(address_hash, params, abi)

    case SmartContract.create_or_update_smart_contract(address_hash, attrs, false) do
      {:ok, _sc} = ok ->
        Logger.info("Huff smart-contract #{address_hash} successfully published")
        ok

      {:error, error} ->
        Logger.error("Huff smart-contract #{address_hash} failed to publish: #{inspect(error)}")
        {:error, error}
    end
  end

  defp unverified_smart_contract(address_hash, params, error, error_message) do
    attrs = attributes(address_hash, params)

    changeset =
      SmartContract.invalid_contract_changeset(
        %SmartContract{address_hash: address_hash},
        attrs,
        error,
        error_message,
        false
      )

    Logger.error("Huff smart-contract verification #{address_hash} failed because of the error #{inspect(error)}")

    %{changeset | action: :insert}
  end

  defp attributes(address_hash, params, abi \\ []) do
    compiler_version = CompilerVersion.get_strict_compiler_version(:huff, params["compiler_version"])

    %{
      address_hash: address_hash,
      name: params["name"],
      compiler_version: compiler_version,
      optimization_runs: nil,
      optimization: false,
      evm_version: params["evm_version"],
      contract_source_code: params["contract_source_code"],
      constructor_arguments: params["constructor_arguments"],
      external_libraries: [],
      secondary_sources: [],
      abi: abi,
      verified_via_sourcify: false,
      verified_via_eth_bytecode_db: false,
      verified_via_verifier_alliance: false,
      partially_verified: false,
      file_path: nil,
      compiler_settings: nil,
      license_type: prepare_license_type(params["license_type"]) || :none,
      is_blueprint: false,
      language: :huff
    }
  end
end

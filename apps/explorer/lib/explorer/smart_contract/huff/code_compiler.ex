defmodule Explorer.SmartContract.Huff.CodeCompiler do
  @moduledoc """
  Compiles Huff source code using selected compiler.
  """

  alias Explorer.SmartContract.HuffDownloader

  @spec run(Keyword.t()) :: {:ok, map} | {:error, :compilation}
  def run(params) do
    compiler_version = Keyword.fetch!(params, :compiler_version)
    code = Keyword.fetch!(params, :code)

    path = HuffDownloader.ensure_exists(compiler_version)
    source_file = create_source_file(code)

    if path do
      {output, status} = System.cmd(path, ["--bytecode", source_file])

      if status == 0 do
        bytecode = String.trim(output)
        {:ok, %{"bytecode" => bytecode, "abi" => []}}
      else
        {:error, :compilation}
      end
    else
      {:error, :compilation}
    end
  end

  defp create_source_file(source) do
    {:ok, path} = Briefly.create(extname: ".huff")
    File.write!(path, source)
    path
  end
end

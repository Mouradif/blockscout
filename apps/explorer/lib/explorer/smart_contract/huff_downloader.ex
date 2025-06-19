defmodule Explorer.SmartContract.HuffDownloader do
  @moduledoc """
  Downloads and caches Huff compiler binaries.
  """
  use GenServer

  @doc "Ensures compiler binary exists and returns its path"
  def ensure_exists(version) do
    path = file_path(version)

    if File.exists?(path) do
      path
    else
      GenServer.call(__MODULE__, {:ensure_exists, version}, 60_000)
    end
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    File.mkdir_p!(compiler_dir())
    {:ok, []}
  end

  @impl true
  def handle_call({:ensure_exists, version}, _from, state) do
    path = file_path(version)

    unless File.exists?(path) do
      tmp = path <> "-tmp"
      contents = download(version)
      File.write!(tmp, contents)
      File.rename(tmp, path)
      System.cmd("chmod", ["+x", path])
    end

    {:reply, path, state}
  end

  defp file_path(version), do: Path.join(compiler_dir(), version)

  defp compiler_dir, do: Application.app_dir(:explorer, "priv/huff_compilers/")

  defp download("huffc") do
    url =
      "https://github.com/huff-language/huff-rs/releases/download/nightly-4c4ae27378224b6a3a1afd35116f0da710ff1418/huffc-linux-x86_64"

    HTTPoison.get!(url, [], timeout: 60_000, recv_timeout: 60_000).body
  end

  defp download("huff-neo") do
    url =
      "https://github.com/cakevm/huff-neo/releases/download/v1.1.14/huff-neo-linux-x86_64"

    HTTPoison.get!(url, [], timeout: 60_000, recv_timeout: 60_000).body
  end
end

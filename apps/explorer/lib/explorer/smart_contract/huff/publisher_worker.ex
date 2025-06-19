defmodule Explorer.SmartContract.Huff.PublisherWorker do
  @moduledoc """
  Background worker for Huff contract verification.
  """

  use Que.Worker, concurrency: 5

  alias Explorer.Chain.Events.Publisher, as: EventsPublisher
  alias Explorer.SmartContract.Huff.Publisher

  def perform({"huff", %{"address_hash" => address_hash} = params}) do
    broadcast(address_hash, [address_hash, params])
  end

  def perform({address_hash, params, %Plug.Conn{} = conn}) do
    broadcast(address_hash, [address_hash, params], conn)
  end

  defp broadcast(address_hash, args, conn \\ nil) do
    result =
      case apply(Publisher, :publish, args) do
        {:ok, _contract} = ok -> ok
        {:error, changeset} -> {:error, changeset}
      end

    if conn do
      EventsPublisher.broadcast(
        [{:contract_verification_result, {String.downcase(address_hash), result, conn}}],
        :on_demand
      )
    else
      EventsPublisher.broadcast([
        {:contract_verification_result, {String.downcase(address_hash), result}}
      ], :on_demand)
    end
  end
end

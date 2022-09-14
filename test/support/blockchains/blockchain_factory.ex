defmodule Mintacoin.BlockchainFactory do
  @moduledoc """
  Allow the creation of blockchains while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.Blockchain

  defmacro __using__(_opts) do
    quote do
      @spec blockchain_factory(attrs :: map()) :: Blockchain.t()
      def blockchain_factory(attrs) do
        blockchain_name = Map.get(attrs, :name, :stellar)
        blockchain_network = Map.get(attrs, :network, :testnet)

        %Blockchain{id: UUID.generate(), name: blockchain_name, network: blockchain_network}
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end

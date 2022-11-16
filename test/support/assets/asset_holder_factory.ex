defmodule Mintacoin.AssetHolderFactory do
  @moduledoc """
  Allow the creation of asset holders while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.AssetHolder

  defmacro __using__(_opts) do
    quote do
      @spec asset_holder_factory(attrs :: map()) :: AssetHolder.t()
      def asset_holder_factory(attrs) do
        account = Map.get(attrs, :account, insert(:account))
        blockchain = Map.get(attrs, :blockchain, insert(:blockchain))
        asset = Map.get(attrs, :asset, insert(:asset))
        is_minter = Map.get(attrs, :is_minter, true)

        wallet =
          case Map.get(attrs, :wallet) do
            nil -> insert(:wallet, %{account: account, blockchain: blockchain})
            wallet -> wallet
          end

        %AssetHolder{
          id: UUID.generate(),
          account: account,
          blockchain: blockchain,
          wallet: wallet,
          asset: asset,
          is_minter: is_minter
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end

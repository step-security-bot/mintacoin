defmodule Mintacoin.BalancesFactory do
  @moduledoc """
  Allow the creation of balances while testing.
  """

  alias Mintacoin.Balance

  defmacro __using__(_opts) do
    quote do
      @spec balance_factory(attrs :: map()) :: Balance.t()
      def balance_factory(attrs) do
        balance = Map.get(attrs, :balance, "100")
        account = Map.get(attrs, :account, insert(:account))
        blockchain = Map.get(attrs, :blockchain, insert(:blockchain))
        asset = Map.get(attrs, :asset, insert(:asset))

        wallet =
          Map.get(attrs, :wallet, insert(:wallet, %{account: account, blockchain: blockchain}))

        %Balance{
          asset: asset,
          wallet: wallet,
          balance: balance
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end

defmodule Mintacoin.Accounts.Crypto do
  @moduledoc """
  This module is responsible to handle the crypto calls for the different blockchains
  """

  @behaviour Mintacoin.Accounts.Crypto.Spec

  alias Mintacoin.{Accounts.Stellar, Blockchain}

  @type status :: :ok | :error
  @type blockchain :: :stellar
  @type impl :: Stellar

  @impl true
  def create_account(params, opts \\ []) do
    blockchain = Keyword.get(opts, :blockchain, Blockchain.default())
    impl(blockchain).create_account(params, opts)
  end

  @spec impl(blockchain :: blockchain()) :: impl()
  defp impl(:stellar), do: Stellar
end

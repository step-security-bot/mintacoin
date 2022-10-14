defmodule Mintacoin.Assets.Crypto do
  @moduledoc """
  This module is responsible to handle the crypto calls for the different blockchains
  """

  @behaviour Mintacoin.Assets.Crypto.Spec

  alias Mintacoin.{Assets.Stellar, Blockchain}

  @type blockchain :: String.t()
  @type impl :: Stellar

  @impl true
  def create_asset(opts \\ []) do
    blockchain = Keyword.get(opts, :blockchain, Blockchain.default())

    impl(blockchain).create_asset(opts)
  end

  @impl true
  def create_trustline(opts \\ []) do
    blockchain = Keyword.get(opts, :blockchain, Blockchain.default())

    impl(blockchain).create_trustline(opts)
  end

  @spec impl(blockchain :: blockchain()) :: impl()
  defp impl("stellar"), do: Application.get_env(:mintacoin, :crypto_impl, Stellar)
end

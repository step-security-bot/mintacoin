defmodule Mintacoin.Accounts.StellarTest do
  @moduledoc """
    This module is used to test functionalities of the Stellar crypto implementation
  """
  use Mintacoin.DataCase, async: false

  import Stellar.KeyPair, only: [random: 0]

  alias Horizon.Accounts.CannedTransactions
  alias Mintacoin.Accounts.{Crypto.AccountResponse, Stellar, StellarMock}

  setup do
    {_public_key, secret_key} = random()
    Application.put_env(:mintacoin, :stellar_fund_secret_key, secret_key)
    Application.put_env(:mintacoin, :horizon, CannedTransactions)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :stellar_fund_secret_key)
      Application.delete_env(:mintacoin, :horizon)
    end)
  end

  describe "mock create_account/1" do
    test "with an existing blockchain" do
      {:ok,
       %AccountResponse{
         tx_id: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129",
         tx_hash: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129"
       }} = StellarMock.create_account([])
    end
  end

  describe "create_account/1" do
    test "Test the complete create account function" do
      {:ok,
       %AccountResponse{
         tx_id: "ab754772dfcbeceed333d1bae5ed219d88166e0ecc897ada240cb25072076c9f",
         tx_hash: "ab754772dfcbeceed333d1bae5ed219d88166e0ecc897ada240cb25072076c9f"
       }} = Stellar.create_account([])
    end
  end
end

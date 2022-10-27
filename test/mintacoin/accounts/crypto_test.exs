defmodule Mintacoin.Accounts.CryptoTest do
  @moduledoc """
    This module is used to test the accounts crypto calls for the different blockchains
  """
  use Mintacoin.DataCase, async: false

  alias Mintacoin.Accounts.{Crypto, Crypto.AccountResponse, StellarMock}

  setup do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)
  end

  describe "create_account/1" do
    test "with the stellar blockchain" do
      {:ok,
       %AccountResponse{
         tx_hash: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129",
         tx_id: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129"
       }} = Crypto.create_account()
    end
  end
end

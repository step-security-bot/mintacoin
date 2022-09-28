defmodule Mintacoin.Accounts.StellarTest do
  @moduledoc """
    This module is used to test functionalities of the Stellar crypto implementation
  """
  use Mintacoin.DataCase, async: false

  alias Mintacoin.Accounts.{Crypto.AccountResponse, StellarMock}

  describe "mock create_account/1" do
    test "with an existing blockchain" do
      {:ok,
       %AccountResponse{
         tx_id: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129",
         tx_hash: "7f82fe6ac195e7674f7bdf7a3416683ffd55c8414978c70bf4da08ac64fea129"
       }} = StellarMock.create_account([])
    end
  end
end

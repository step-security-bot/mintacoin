defmodule Mintacoin.Accounts.CryptoTest do
  @moduledoc """
    This module is used to test the accounts crypto calls for the different blockchains
  """
  use Mintacoin.DataCase, async: false

  alias Mintacoin.Accounts.Crypto

  describe "create_account/2" do
    test "with the stellar blockchain" do
      {:ok, %{successful: true}} = Crypto.create_account(%{})
    end
  end
end

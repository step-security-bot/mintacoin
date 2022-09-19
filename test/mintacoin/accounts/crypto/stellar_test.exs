defmodule Mintacoin.Accounts.StellarTest do
  @moduledoc """
    This module is used to test functionalities of the Stellar crypto implementation
  """
  use Mintacoin.DataCase, async: false

  alias Mintacoin.Accounts.Stellar

  describe "create_account/2" do
    test "with an existing blockchain" do
      {:ok, %{successful: true}} = Stellar.create_account(%{}, :stellar)
    end
  end
end

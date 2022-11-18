defmodule Mintacoin.Payments.StellarTest do
  @moduledoc """
  This module is used to test functionalities of the Stellar crypto implementation
  """
  use Mintacoin.DataCase, async: false

  import Stellar.KeyPair, only: [random: 0]
  alias Horizon.Payments.CannedTransactions
  alias Mintacoin.Payments.{Crypto.PaymentResponse, Stellar, StellarMock}

  setup do
    {_public_key, secret_key} = random()
    Application.put_env(:mintacoin, :stellar_fund_secret_key, secret_key)
    Application.put_env(:mintacoin, :horizon, CannedTransactions)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :stellar_fund_secret_key)
      Application.delete_env(:mintacoin, :horizon)
    end)

    %{
      source_secret_key: secret_key,
      destination_public_key: "BBB",
      amount: "10.0",
      asset_code: "AAA"
    }
  end

  describe "create_payment/1 mock" do
    test "with an existing blockchain" do
      {
        :ok,
        %PaymentResponse{
          tx_id: "200dbe2ed52eb76bb850a842494ef47e9b266426e6a8326e9309ec1ed66af3d9",
          tx_hash: "200dbe2ed52eb76bb850a842494ef47e9b266426e6a8326e9309ec1ed66af3d9"
        }
      } = StellarMock.create_payment([])
    end
  end

  describe "create_payment/1" do
    test "Test the complete create payment function", %{
      source_secret_key: source_secret_key,
      destination_public_key: destination_public_key,
      amount: amount,
      asset_code: asset_code
    } do
      {:ok,
       %PaymentResponse{
         tx_id: "fb51387be014c13a7d62d6950b85519e08167360f7d56b4fb985154bc1840eb2",
         tx_hash: "fb51387be014c13a7d62d6950b85519e08167360f7d56b4fb985154bc1840eb2"
       }} =
        Stellar.create_payment(
          source_secret_key: source_secret_key,
          destination_public_key: destination_public_key,
          amount: amount,
          asset_code: asset_code
        )
    end
  end
end

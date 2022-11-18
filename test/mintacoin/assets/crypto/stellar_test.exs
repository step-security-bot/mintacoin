defmodule Mintacoin.Assets.StellarTest do
  @moduledoc """
  This module is used to test functionalities of the Stellar crypto implementation
  """
  use Mintacoin.DataCase, async: false

  import Stellar.KeyPair, only: [random: 0]

  alias Horizon.Assets.CannedTransactions
  alias Mintacoin.Assets.{Crypto.AssetResponse, Stellar, StellarMock}

  setup do
    {_public_key, secret_key} = random()
    Application.put_env(:mintacoin, :stellar_fund_secret_key, secret_key)
    Application.put_env(:mintacoin, :horizon, CannedTransactions)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :stellar_fund_secret_key)
      Application.delete_env(:mintacoin, :horizon)
    end)

    %{
      secret_key: secret_key,
      asset_code: "ABC",
      asset_supply: 10
    }
  end

  describe "mock create_asset/1" do
    test "with an existing blockchain" do
      {:ok,
       %AssetResponse{
         tx_id: "cda25a0c343a411a3ca2927d48454abaff9ccbebd8a5c292695d0aec30b133ca",
         tx_hash: "cda25a0c343a411a3ca2927d48454abaff9ccbebd8a5c292695d0aec30b133ca"
       }} = StellarMock.create_asset([])
    end
  end

  describe "mock create_trustline/1" do
    test "with an existing blockchain" do
      {:ok,
       %AssetResponse{
         tx_id: "22eb025e2281b2e35b2bd51bc5a3a102e8129b56dd1fc52145c0ce20dfcfe6c0",
         tx_hash: "22eb025e2281b2e35b2bd51bc5a3a102e8129b56dd1fc52145c0ce20dfcfe6c0"
       }} = StellarMock.create_trustline([])
    end
  end

  describe "create_asset/1" do
    test "Test the complete create_asset function", %{
      secret_key: secret_key,
      asset_code: asset_code,
      asset_supply: asset_supply
    } do
      {:ok,
       %AssetResponse{
         tx_id: "fb857cdf3f9dd91c6d7101b98d90286df43e9d383f6f0826b91ae5211a7f34b5",
         tx_hash: "fb857cdf3f9dd91c6d7101b98d90286df43e9d383f6f0826b91ae5211a7f34b5"
       }} =
        Stellar.create_asset(
          distributor_secret_key: secret_key,
          asset_code: asset_code,
          asset_supply: asset_supply
        )
    end
  end

  describe "create_trustline/1" do
    test "Test create a trustline with an existing blockchain", %{
      secret_key: secret_key,
      asset_code: asset_code
    } do
      {:ok,
       %AssetResponse{
         tx_id: "fb857cdf3f9dd91c6d7101b98d90286df43e9d383f6f0826b91ae5211a7f34b5",
         tx_hash: "fb857cdf3f9dd91c6d7101b98d90286df43e9d383f6f0826b91ae5211a7f34b5"
       }} = Stellar.create_trustline(trustor_secret_key: secret_key, asset_code: asset_code)
    end
  end
end

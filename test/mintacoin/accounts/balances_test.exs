defmodule Mintacoin.BalancesTest do
  @moduledoc """
  This module is used to group common tests for Balance functions
  """

  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.{Adapters.SQL.Sandbox, Changeset}
  alias Mintacoin.{Balance, Balances}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    wallet = insert(:wallet)
    asset = insert(:asset)

    balance = insert(:balance, %{balance: "10"})

    %{
      wallet: wallet,
      asset: asset,
      balance: balance,
      balance_amount: "1234.747474",
      not_existing_uuid: "4b70e51f-380b-4e00-b6c3-37e8afff8415"
    }
  end

  describe "create/1" do
    test "with valid params", %{
      wallet: %{id: wallet_id},
      asset: %{id: asset_id},
      balance_amount: balance_amount
    } do
      {:ok, %Balance{asset_id: ^asset_id, wallet_id: ^wallet_id, balance: ^balance_amount}} =
        Balances.create(%{asset_id: asset_id, wallet_id: wallet_id, balance: balance_amount})
    end

    test "with an existing wallet and asset", %{
      balance: %{wallet_id: wallet_id, asset_id: asset_id},
      balance_amount: balance_amount
    } do
      {:error,
       %Changeset{
         errors: [
           {:asset_id, {"has already been taken", _detail}}
           | _tail
         ]
       }} = Balances.create(%{asset_id: asset_id, wallet_id: wallet_id, balance: balance_amount})
    end

    test "with missing params" do
      {:error,
       %Changeset{
         errors: [
           asset_id: {"can't be blank", _},
           wallet_id: {"can't be blank", _}
         ]
       }} = Balances.create(%{})
    end

    test "when asset_id doesn't exist", %{
      wallet: %{id: wallet_id},
      balance_amount: balance_amount,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:asset_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Balances.create(%{
          asset_id: not_existing_uuid,
          wallet_id: wallet_id,
          balance: balance_amount
        })
    end

    test "when wallet_id doesn't exist", %{
      asset: %{id: asset_id},
      balance_amount: balance_amount,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:wallet_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Balances.create(%{
          asset_id: asset_id,
          wallet_id: not_existing_uuid,
          balance: balance_amount
        })
    end
  end

  describe "update/2" do
    test "with valid params", %{balance: %{id: balance_id}} do
      {:ok, %Balance{id: ^balance_id, balance: "20.734766"}} =
        Balances.update(balance_id, %{balance: "20.734766"})
    end
  end

  describe "increase_balance/2" do
    test "with valid params", %{balance: %{id: balance_id}} do
      {:ok, %Balance{id: ^balance_id, balance: "30.5478"}} =
        Balances.increase_balance(balance_id, "20.5478")
    end
  end

  describe "update_by_wallet_id_and_asset_id/2" do
    test "with valid params", %{
      balance: %{id: balance_id, wallet_id: wallet_id, asset_id: asset_id}
    } do
      {:ok, %Balance{id: ^balance_id, balance: "20.47634"}} =
        Balances.update_by_wallet_id_and_asset_id(wallet_id, asset_id, %{balance: "20.47634"})
    end
  end

  describe "retrieve_by_wallet_id/1" do
    test "when wallet exist", %{balance: %{id: balance_id, wallet_id: wallet_id}} do
      {:ok, [%Balance{id: ^balance_id}]} = Balances.retrieve_by_wallet_id(wallet_id)
    end

    test "when wallet doesn't exist", %{not_existing_uuid: not_existing_uuid} do
      {:ok, []} = Balances.retrieve_by_wallet_id(not_existing_uuid)
    end
  end

  describe "retrieve_by_wallet_id_and_asset_id/2" do
    test "with valid params", %{
      balance: %{id: balance_id, wallet_id: wallet_id, asset_id: asset_id}
    } do
      {:ok, %Balance{id: ^balance_id, wallet_id: ^wallet_id, asset_id: ^asset_id}} =
        Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end

    test "when wallet doesn't exist", %{
      balance: %{asset_id: asset_id},
      not_existing_uuid: not_existing_uuid
    } do
      {:ok, nil} = Balances.retrieve_by_wallet_id_and_asset_id(not_existing_uuid, asset_id)
    end

    test "when asset doesn't exist", %{
      balance: %{wallet_id: wallet_id},
      not_existing_uuid: not_existing_uuid
    } do
      {:ok, nil} = Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, not_existing_uuid)
    end
  end

  describe "retrieve_by_account_id_and_blockchain_id/2" do
    setup do
      account = insert(:account)
      blockchain = insert(:blockchain)
      asset = insert(:asset)
      wallet = insert(:wallet, %{account: account, blockchain: blockchain})
      balance = insert(:balance, %{wallet: wallet, asset: asset})

      %{
        account: account,
        wallet: wallet,
        blockchain: blockchain,
        balance: balance
      }
    end

    test "with valid params", %{
      blockchain: %{id: blockchain_id},
      account: %{id: account_id},
      balance: %{id: balance_id}
    } do
      {:ok, [%Balance{id: ^balance_id}]} =
        Balances.retrieve_by_account_id_and_blockchain_id(account_id, blockchain_id)
    end

    test "when account doesn't exist", %{
      not_existing_uuid: not_existing_uuid,
      blockchain: %{id: blockchain_id}
    } do
      {:ok, []} =
        Balances.retrieve_by_account_id_and_blockchain_id(not_existing_uuid, blockchain_id)
    end

    test "when blockchain doesn't exist", %{
      not_existing_uuid: not_existing_uuid,
      account: %{id: account_id}
    } do
      {:ok, []} = Balances.retrieve_by_account_id_and_blockchain_id(account_id, not_existing_uuid)
    end
  end
end

defmodule Mintacoin.Assets.AssetHoldersTest do
  @moduledoc """
  This module is used to group common tests for Asset Holders functions
  """

  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 1]

  alias Ecto.{Adapters.SQL.Sandbox, Changeset}
  alias Mintacoin.{AssetHolder, AssetHolders}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    asset_holder = insert(:asset_holder)
    account = insert(:account)
    asset = insert(:asset)
    %{id: wallet_id, blockchain_id: blockchain_id} = insert(:wallet)

    %{
      account: account,
      asset: asset,
      wallet_id: wallet_id,
      blockchain_id: blockchain_id,
      asset_holder: asset_holder,
      is_minter: true,
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create/1" do
    test "with valid params", %{
      account: %{id: account_id},
      asset: %{id: asset_id},
      wallet_id: wallet_id,
      blockchain_id: blockchain_id,
      is_minter: is_minter
    } do
      {:ok,
       %AssetHolder{
         account_id: ^account_id,
         asset_id: ^asset_id,
         wallet_id: ^wallet_id,
         blockchain_id: ^blockchain_id,
         is_minter: ^is_minter
       }} =
        AssetHolders.create(%{
          account_id: account_id,
          asset_id: asset_id,
          wallet_id: wallet_id,
          blockchain_id: blockchain_id,
          is_minter: is_minter
        })
    end

    test "when account doesn't exist", %{
      asset: %{id: asset_id},
      wallet_id: wallet_id,
      blockchain_id: blockchain_id,
      is_minter: is_minter,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:account_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        AssetHolders.create(%{
          account_id: not_existing_uuid,
          asset_id: asset_id,
          wallet_id: wallet_id,
          blockchain_id: blockchain_id,
          is_minter: is_minter
        })
    end

    test "when blockchain doesn't exist", %{
      asset: %{id: asset_id},
      wallet_id: wallet_id,
      account: %{id: account_id},
      is_minter: is_minter,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:blockchain_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        AssetHolders.create(%{
          account_id: account_id,
          asset_id: asset_id,
          wallet_id: wallet_id,
          blockchain_id: not_existing_uuid,
          is_minter: is_minter
        })
    end

    test "when wallet doesn't exist", %{
      account: %{id: account_id},
      asset: %{id: asset_id},
      blockchain_id: blockchain_id,
      is_minter: is_minter,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:wallet_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        AssetHolders.create(%{
          account_id: account_id,
          asset_id: asset_id,
          wallet_id: not_existing_uuid,
          blockchain_id: blockchain_id,
          is_minter: is_minter
        })
    end

    test "when asset doesn't exist", %{
      account: %{id: account_id},
      blockchain_id: blockchain_id,
      wallet_id: wallet_id,
      is_minter: is_minter,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:asset_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        AssetHolders.create(%{
          account_id: account_id,
          asset_id: not_existing_uuid,
          wallet_id: wallet_id,
          blockchain_id: blockchain_id,
          is_minter: is_minter
        })
    end

    test "without params" do
      {:error,
       %Changeset{
         errors: [
           blockchain_id: {"can't be blank", _},
           account_id: {"can't be blank", _},
           asset_id: {"can't be blank", _},
           wallet_id: {"can't be blank", _}
         ]
       }} = AssetHolders.create(%{})
    end

    test "when account_id and wallet_id exist", %{
      asset_holder: %{wallet_id: wallet_id, asset_id: asset_id},
      account: %{id: account_id},
      blockchain_id: blockchain_id,
      is_minter: is_minter
    } do
      {:error,
       %Changeset{
         errors: [
           asset_id: {"has already been taken", _}
         ]
       }} =
        AssetHolders.create(%{
          account_id: account_id,
          asset_id: asset_id,
          wallet_id: wallet_id,
          blockchain_id: blockchain_id,
          is_minter: is_minter
        })
    end
  end

  describe "retrieve_by_id/1" do
    test "when asset holder exists", %{
      asset_holder: %{id: asset_holder_id}
    } do
      {:ok, %AssetHolder{id: ^asset_holder_id}} = AssetHolders.retrieve_by_id(asset_holder_id)
    end

    test "when asset holder does not exists", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = AssetHolders.retrieve_by_id(not_existing_uuid)
    end
  end

  describe "retrieve_by_account_id_and_asset_id/2" do
    test "when account and asset exists", %{
      asset_holder: %{id: asset_holder_id, account_id: account_id, asset_id: asset_id}
    } do
      {:ok, %AssetHolder{id: ^asset_holder_id}} =
        AssetHolders.retrieve_by_account_id_and_asset_id(account_id, asset_id)
    end

    test "when account does not exists", %{
      not_existing_uuid: not_existing_uuid,
      asset_holder: %{asset_id: asset_id}
    } do
      {:ok, nil} = AssetHolders.retrieve_by_account_id_and_asset_id(asset_id, not_existing_uuid)
    end

    test "when asset does not exists", %{
      not_existing_uuid: not_existing_uuid,
      asset_holder: %{account_id: account_id}
    } do
      {:ok, nil} = AssetHolders.retrieve_by_account_id_and_asset_id(not_existing_uuid, account_id)
    end
  end

  describe "retrieve_by_wallet_id_and_asset_id/2" do
    test "when wallet exists", %{
      asset_holder: %{id: asset_holder_id, wallet_id: wallet_id, asset_id: asset_id}
    } do
      {:ok, %AssetHolder{id: ^asset_holder_id}} =
        AssetHolders.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end

    test "when wallet does not exists", %{
      asset_holder: %{wallet_id: wallet_id},
      not_existing_uuid: not_existing_uuid
    } do
      {:ok, nil} = AssetHolders.retrieve_by_wallet_id_and_asset_id(wallet_id, not_existing_uuid)
    end

    test "when asset does not exists", %{
      asset_holder: %{asset_id: asset_id},
      not_existing_uuid: not_existing_uuid
    } do
      {:ok, nil} = AssetHolders.retrieve_by_wallet_id_and_asset_id(not_existing_uuid, asset_id)
    end
  end
end

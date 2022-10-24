defmodule Mintacoin.Accounts.WalletsTest do
  @moduledoc """
    This module is used to group common tests for Walltes functions
  """

  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.{Adapters.SQL.Sandbox, Changeset}
  alias Mintacoin.{Account, Blockchain, Wallet, Wallets}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    %{
      public_key: "IARC6FWCGKQPNIX5ITKHKNVYNL6AXVCB6XTJMWVJGUVEJOG5J7FQ",
      encrypted_secret_key:
        "oCZIdnWX8ZF6cHJ5CJbdmc5wmDzoLoXi+SnwQYzHv3GtmDwqc/ATx4MktFMo3lzGLaCwanD084dHyvGaQQlNOkcqss3Hgr8gxsb64xk+Gyc",
      secret_key: "MKMO5J4VQDIPTQ52FUC2DZN4DTFM4L3TCLQFND64CSTKJADR4GGQ",
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create/1" do
    setup do
      %Account{id: account_id} = insert(:account)
      %Blockchain{id: blockchain_id} = insert(:blockchain, %{name: "stellar", network: "mainnet"})

      %{
        account_id: account_id,
        blockchain_id: blockchain_id
      }
    end

    test "with valid params", %{
      public_key: public_key,
      encrypted_secret_key: encrypted_secret_key,
      secret_key: secret_key,
      account_id: account_id,
      blockchain_id: blockchain_id
    } do
      {:ok,
       %Wallet{
         public_key: ^public_key,
         encrypted_secret_key: ^encrypted_secret_key,
         secret_key: ^secret_key,
         account_id: ^account_id,
         blockchain_id: ^blockchain_id
       }} =
        Wallets.create(%{
          public_key: public_key,
          encrypted_secret_key: encrypted_secret_key,
          secret_key: secret_key,
          account_id: account_id,
          blockchain_id: blockchain_id
        })
    end

    test "with missing param" do
      {:error,
       %Changeset{
         errors: [
           public_key: {"can't be blank", _},
           encrypted_secret_key: {"can't be blank", _},
           secret_key: {"can't be blank", _},
           account_id: {"can't be blank", _},
           blockchain_id: {"can't be blank", _}
         ]
       }} = Wallets.create(%{})
    end

    test "when account_id doesn't exist", %{
      public_key: public_key,
      encrypted_secret_key: encrypted_secret_key,
      secret_key: secret_key,
      blockchain_id: blockchain_id,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:account_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Wallets.create(%{
          public_key: public_key,
          encrypted_secret_key: encrypted_secret_key,
          secret_key: secret_key,
          account_id: not_existing_uuid,
          blockchain_id: blockchain_id
        })
    end

    test "when blockchain_id doesn't exist", %{
      public_key: public_key,
      encrypted_secret_key: encrypted_secret_key,
      secret_key: secret_key,
      account_id: account_id,
      not_existing_uuid: not_existing_uuid
    } do
      {:error,
       %Changeset{
         errors: [
           {:blockchain_id, {"does not exist", _detail}}
           | _tail
         ]
       }} =
        Wallets.create(%{
          public_key: public_key,
          encrypted_secret_key: encrypted_secret_key,
          secret_key: secret_key,
          account_id: account_id,
          blockchain_id: not_existing_uuid
        })
    end
  end

  describe "create/1 when wallet already exist" do
    setup [:create_wallet, :new_params]

    test "with same user on different blockchain network", %{
      new_public_key: new_public_key,
      new_encrypted_secret_key: new_encrypted_secret_key,
      new_secret_key: new_secret_key,
      account: %{id: account_id},
      new_blockchain: %{id: new_blockchain_id}
    } do
      {:ok,
       %Wallet{
         public_key: ^new_public_key,
         encrypted_secret_key: ^new_encrypted_secret_key,
         secret_key: ^new_secret_key,
         blockchain_id: ^new_blockchain_id,
         account_id: ^account_id
       }} =
        Wallets.create(%{
          public_key: new_public_key,
          encrypted_secret_key: new_encrypted_secret_key,
          secret_key: new_secret_key,
          account_id: account_id,
          blockchain_id: new_blockchain_id
        })
    end

    test "with same user and same blockchain", %{
      new_public_key: new_public_key,
      new_encrypted_secret_key: new_encrypted_secret_key,
      new_secret_key: new_secret_key,
      account: %{id: account_id},
      blockchain: %{id: blockchain_id}
    } do
      {:error,
       %Changeset{
         errors: [
           {:account_id, {"has already been taken", _detail}}
           | _tail
         ]
       }} =
        Wallets.create(%{
          public_key: new_public_key,
          encrypted_secret_key: new_encrypted_secret_key,
          secret_key: new_secret_key,
          account_id: account_id,
          blockchain_id: blockchain_id
        })
    end

    test "with an existing public key", %{
      public_key: public_key,
      new_encrypted_secret_key: new_encrypted_secret_key,
      new_secret_key: new_secret_key,
      new_account: %{id: new_account_id},
      blockchain: %{id: blockchain_id}
    } do
      {:error,
       %Changeset{
         errors: [
           {:public_key, {"has already been taken", _detail}}
           | _tail
         ]
       }} =
        Wallets.create(%{
          public_key: public_key,
          encrypted_secret_key: new_encrypted_secret_key,
          secret_key: new_secret_key,
          account_id: new_account_id,
          blockchain_id: blockchain_id
        })
    end
  end

  describe "retrieve_by_id/1" do
    setup [:create_wallet]

    test "when wallet exist", %{wallet: %{id: wallet_id}} do
      {:ok, %Wallet{id: ^wallet_id}} = Wallets.retrieve_by_id(wallet_id)
    end

    test "when wallet doesn't exist and is valid value", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = Wallets.retrieve_by_id(not_existing_uuid)
    end
  end

  describe "retrieve_by_public_key/1" do
    setup [:create_wallet]

    test "when wallet exist", %{public_key: public_key} do
      {:ok, %Wallet{public_key: ^public_key}} = Wallets.retrieve_by_public_key(public_key)
    end

    test "when wallet doesn't exist and key is valid", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = Wallets.retrieve_by_public_key(not_existing_uuid)
    end
  end

  describe "retrieve_by_account_id_and_blockchain_id/2" do
    setup [:create_wallet]

    test "when wallet exist", %{
      wallet: %{id: wallet_id},
      account: %{id: account_id},
      blockchain: %{id: blockchain_id}
    } do
      {:ok, %Wallet{id: ^wallet_id}} =
        Wallets.retrieve_by_account_id_and_blockchain_id(account_id, blockchain_id)
    end

    test "when account_id doesn't exist", %{
      not_existing_uuid: not_existing_uuid,
      blockchain: %{id: blockchain_id}
    } do
      {:ok, nil} =
        Wallets.retrieve_by_account_id_and_blockchain_id(not_existing_uuid, blockchain_id)
    end

    test "when blockchain_id doesn't exist", %{
      not_existing_uuid: not_existing_uuid,
      account: %{id: account_id}
    } do
      {:ok, nil} = Wallets.retrieve_by_account_id_and_blockchain_id(account_id, not_existing_uuid)
    end
  end

  describe "retrieve_by_account_address_and_blockchain_id/2" do
    setup [:create_wallet]

    test "when wallet exist", %{
      wallet: %{id: wallet_id},
      account: %{address: address},
      blockchain: %{id: blockchain_id}
    } do
      {:ok, %Wallet{id: ^wallet_id}} =
        Wallets.retrieve_by_account_address_and_blockchain_id(address, blockchain_id)
    end

    test "when address doesn't exist", %{blockchain: %{id: blockchain_id}} do
      {:ok, nil} = Wallets.retrieve_by_account_address_and_blockchain_id("address", blockchain_id)
    end

    test "when blockchain_id doesn't exist", %{
      not_existing_uuid: not_existing_uuid,
      account: %{address: address}
    } do
      {:ok, nil} =
        Wallets.retrieve_by_account_address_and_blockchain_id(address, not_existing_uuid)
    end
  end

  defp create_wallet(%{public_key: public_key}) do
    %Wallet{blockchain: blockchain, account: account} =
      wallet = insert(:wallet, %{public_key: public_key})

    %{wallet: wallet, blockchain: blockchain, account: account}
  end

  defp new_params(_context) do
    account = insert(:account)
    blockchain = insert(:blockchain, %{name: "stellar", network: "mainnet"})

    %{
      new_public_key: "GZUFMBN4LYBYQSMSS7FOR6LYYB5HU4VAIK3ZXSNBCRMB6F7N45WA",
      new_encrypted_secret_key:
        "x+evrxdb3OnVPtPi2E4XXAC66xUIaxId4aqQkxWqntE2A09qZB+aNpRvKvXlUcvvpOW3J6ttwO4GS97eLeZlZMgqB2WuhdLJrrQXYwV6sS8",
      new_secret_key: "AS5PII43PD7WYSXABMUBDHIJHMPJGWGNGI62VO7UJQOCRKB3UYNQ",
      new_account: account,
      new_blockchain: blockchain
    }
  end
end

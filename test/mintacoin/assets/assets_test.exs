defmodule Mintacoin.Assets.AssetsTest do
  @moduledoc """
  This module is used to group common tests for Assets functions
  """

  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.{Adapters.SQL.Sandbox, Changeset}

  alias Mintacoin.{
    Accounts.Cipher,
    Asset,
    Assets,
    Assets.StellarMock
  }

  alias Mintacoin.Assets.Workers.CreateAsset, as: CreateAssetWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    asset = insert(:asset)

    %{
      asset: asset,
      code: "MTK",
      supply: "1000",
      new_code: "ART",
      new_supply: "440.20",
      integer_supply: 440,
      float_supply: 443.323_343,
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create_db_record/1" do
    test "with valid params", %{code: code, supply: supply} do
      {:ok, %Asset{code: ^code, supply: ^supply}} =
        Assets.create_db_record(%{code: code, supply: supply})
    end

    test "with invalid code", %{supply: supply} do
      {:error,
       %Changeset{
         errors: [
           {:code, {"code must be alphanumeric", _detail}}
           | _tail
         ]
       }} = Assets.create_db_record(%{code: "M&L", supply: supply})
    end

    test "with invalid supply", %{code: code} do
      {:error,
       %Changeset{
         errors: [
           {:supply, {"is invalid", _detail}}
           | _tail
         ]
       }} = Assets.create_db_record(%{code: code, supply: -1})
    end

    test "when missing params" do
      {:error,
       %Changeset{
         errors: [
           code: {"can't be blank", _},
           supply: {"can't be blank", _}
         ]
       }} = Assets.create_db_record(%{})
    end
  end

  describe "update/2" do
    test "with valid supply", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id, supply: "100"}} = Assets.update(id, %{supply: "100"})
    end
  end

  describe "increase_supply/2" do
    test "with valid amount", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id, supply: "1100.876786"}} = Assets.increase_supply(id, "100.876786")
    end
  end

  describe "retrieve_by_id/1" do
    test "when id exist", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id}} = Assets.retrieve_by_id(id)
    end

    test "when id doesn't exist", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = Assets.retrieve_by_id(not_existing_uuid)
    end
  end

  describe "create/1" do
    setup [:successful_transaction, :create_user_wallet, :create_asset_in_network]

    test "enqueuing create asset job", %{
      wallet: wallet,
      signature: signature,
      new_code: code,
      new_supply: supply
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, %Asset{}} =
          Assets.create(%{
            wallet: wallet,
            signature: signature,
            asset_code: code,
            asset_supply: supply
          })

        assert_enqueued(
          worker: CreateAssetWorker,
          queue: :create_asset_queue
        )
      end)
    end

    test "when is a new asset for the user", %{
      wallet: wallet,
      signature: signature,
      new_code: asset_code,
      new_supply: asset_supply
    } do
      {:ok, %Asset{supply: ^asset_supply}} =
        Assets.create(%{
          wallet: wallet,
          signature: signature,
          asset_code: asset_code,
          asset_supply: asset_supply
        })
    end

    test "with integer supply", %{
      wallet: wallet,
      signature: signature,
      new_code: asset_code,
      integer_supply: asset_supply
    } do
      string_supply = Integer.to_string(asset_supply)

      {:ok, %Asset{supply: ^string_supply}} =
        Assets.create(%{
          wallet: wallet,
          signature: signature,
          asset_code: asset_code,
          asset_supply: asset_supply
        })
    end

    test "with float supply", %{
      wallet: wallet,
      signature: signature,
      new_code: asset_code,
      float_supply: asset_supply
    } do
      string_supply = Float.to_string(asset_supply)

      {:ok, %Asset{supply: ^string_supply}} =
        Assets.create(%{
          wallet: wallet,
          signature: signature,
          asset_code: asset_code,
          asset_supply: asset_supply
        })
    end

    test "with invalid supply", %{
      wallet: wallet,
      signature: signature,
      new_code: asset_code
    } do
      {:error, :invalid_supply_format} =
        Assets.create(%{
          wallet: wallet,
          signature: signature,
          asset_code: asset_code,
          asset_supply: "444,333"
        })
    end

    test "with negative supply", %{
      wallet: wallet,
      signature: signature,
      new_code: asset_code
    } do
      {:error, :invalid_supply_format} =
        Assets.create(%{
          wallet: wallet,
          signature: signature,
          asset_code: asset_code,
          asset_supply: -123
        })
    end

    test "with invalid asset code", %{
      wallet: wallet,
      signature: signature,
      new_supply: asset_supply
    } do
      {:error,
       %Changeset{
         errors: [
           {:code, {"code must be alphanumeric", _detail}}
           | _tail
         ]
       }} =
        Assets.create(%{
          wallet: wallet,
          signature: signature,
          asset_code: "GG&2",
          asset_supply: asset_supply
        })
    end

    test "with invalid signature", %{
      wallet: wallet,
      new_code: asset_code,
      new_supply: asset_supply
    } do
      {:error, :decoding_error} =
        Assets.create(%{
          wallet: wallet,
          signature: "OR4N6LBCSWMBNPJEW6KBZ62LQNKW4H7WPE5MNIOIX732LQXBU67",
          asset_code: asset_code,
          asset_supply: asset_supply
        })
    end

    test "when the user create the same asset", %{
      asset: %{id: asset_id},
      wallet: wallet,
      signature: signature,
      code: asset_code,
      supply: asset_supply,
      new_supply: new_supply
    } do
      {:ok, %Asset{id: ^asset_id}} =
        Assets.create(%{
          wallet: wallet,
          signature: signature,
          asset_code: asset_code,
          asset_supply: new_supply
        })

      end_supply = add(asset_supply, new_supply)

      {:ok, %{supply: ^end_supply}} = Assets.retrieve_by_id(asset_id)
    end
  end

  defp create_user_wallet(_context) do
    blockchain = insert(:blockchain, %{name: "stellar"})
    %{signature: signature} = account = insert(:account)

    secret_key = "SBJCNL6H5WFDK2CUAWU2IAWGWQLGER77URPYXUJ5B4N4GY2HNEBL5JJG"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    %{
      blockchain: blockchain,
      account: account,
      wallet: wallet,
      signature: signature
    }
  end

  defp create_asset_in_network(%{
         wallet: wallet,
         signature: signature,
         code: code,
         supply: supply
       }) do
    {:ok, asset} =
      Assets.create(%{
        wallet: wallet,
        signature: signature,
        asset_code: code,
        asset_supply: supply
      })

    %{asset: asset}
  end

  defp successful_transaction(_context) do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)
    Application.put_env(:stellar_mock, :tx_status, true)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
      Application.delete_env(:stellar_mock, :tx_status)
    end)
  end

  # adds and returns a string
  defp add(a, b) do
    a
    |> Decimal.add(b)
    |> Decimal.to_string(:normal)
  end
end

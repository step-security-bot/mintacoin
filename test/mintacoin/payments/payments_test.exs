defmodule Mintacoin.Payments.PaymentsTest do
  @moduledoc """
  This module is used to group common tests for Payments functions
  """
  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset
  alias Mintacoin.{Payment, Payments}
  alias Mintacoin.Payments.Workers.CreatePayment, as: CreatePaymentWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    blockchain = insert(:blockchain)
    asset = insert(:asset)
    amount = "734.345667"
    status = :processing
    new_status = :completed
    successful = false
    new_successful = true

    %{account: source_account, wallet: source_wallet} =
      insert(:asset_holder, %{
        blockchain: blockchain,
        asset: asset,
        is_minter: false
      })

    %{account: destination_account} =
      insert(:asset_holder, %{
        blockchain: blockchain,
        asset: asset,
        is_minter: false
      })

    insert(:balance, %{
      wallet: source_wallet,
      asset: asset,
      balance: "10000.0"
    })

    payment =
      insert(:payment, %{source_account: source_account, destination_account: destination_account})

    %{
      payment: payment,
      blockchain: blockchain,
      asset: asset,
      source_account: source_account,
      destination_account: destination_account,
      amount: amount,
      status: status,
      new_status: new_status,
      successful: successful,
      new_successful: new_successful,
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create/1" do
    test "with valid params", %{
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      source_account: %{id: source_account_id, signature: source_signature},
      destination_account: %{id: destination_account_id},
      amount: amount,
      status: status,
      successful: successful
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok,
         %Payment{
           blockchain_id: ^blockchain_id,
           source_account_id: ^source_account_id,
           destination_account_id: ^destination_account_id,
           asset_id: ^asset_id,
           amount: ^amount,
           status: ^status,
           successful: ^successful
         }} =
          Payments.create(%{
            source_signature: source_signature,
            source_account_id: source_account_id,
            destination_account_id: destination_account_id,
            blockchain_id: blockchain_id,
            asset_id: asset_id,
            amount: amount
          })

        assert_enqueued(
          worker: CreatePaymentWorker,
          queue: :create_payment_queue
        )
      end)
    end

    test "when the destination doesn't have a trustline with the asset", %{
      blockchain: %{id: blockchain_id} = blockchain,
      asset: %{id: asset_id},
      source_account: %{id: source_account_id, signature: source_signature}
    } do
      %{id: destination_account_id} = account = insert(:account)
      insert(:wallet, account: account, blockchain: blockchain)

      Oban.Testing.with_testing_mode(:manual, fn ->
        {:error, :destination_trustline_not_found} =
          Payments.create(%{
            source_signature: source_signature,
            source_account_id: source_account_id,
            destination_account_id: destination_account_id,
            blockchain_id: blockchain_id,
            asset_id: asset_id,
            amount: "1000"
          })

        refute_enqueued(
          worker: CreatePaymentWorker,
          queue: :create_payment_queue
        )
      end)
    end

    test "when the amount exceeds the source account balance", %{
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      source_account: %{id: source_account_id, signature: source_signature},
      destination_account: %{id: destination_account_id}
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:error, :insufficient_funds} =
          Payments.create(%{
            source_signature: source_signature,
            source_account_id: source_account_id,
            destination_account_id: destination_account_id,
            blockchain_id: blockchain_id,
            asset_id: asset_id,
            amount: "20000"
          })

        refute_enqueued(
          worker: CreatePaymentWorker,
          queue: :create_payment_queue
        )
      end)
    end

    test "when the source balance doesn't exist", %{
      blockchain: %{id: blockchain_id} = blockchain,
      asset: %{id: asset_id} = asset,
      destination_account: %{id: destination_account_id}
    } do
      %{account: %{id: source_account_id, signature: source_signature}} =
        insert(:asset_holder, %{
          blockchain: blockchain,
          asset: asset,
          is_minter: false
        })

      Oban.Testing.with_testing_mode(:manual, fn ->
        {:error, :source_balance_not_found} =
          Payments.create(%{
            source_signature: source_signature,
            source_account_id: source_account_id,
            destination_account_id: destination_account_id,
            blockchain_id: blockchain_id,
            asset_id: asset_id,
            amount: "20000"
          })

        refute_enqueued(
          worker: CreatePaymentWorker,
          queue: :create_payment_queue
        )
      end)
    end

    test "when the supply has an invalid format", %{
      blockchain: %{id: blockchain_id},
      asset: %{id: asset_id},
      source_account: %{id: source_account_id, signature: source_signature},
      destination_account: %{id: destination_account_id}
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:error, :invalid_supply_format} =
          Payments.create(%{
            source_signature: source_signature,
            source_account_id: source_account_id,
            destination_account_id: destination_account_id,
            blockchain_id: blockchain_id,
            asset_id: asset_id,
            amount: "invalid-supply"
          })

        refute_enqueued(
          worker: CreatePaymentWorker,
          queue: :create_payment_queue
        )
      end)
    end
  end

  describe "update/2" do
    test "with valid params", %{
      payment: %{id: payment_id},
      new_status: new_status,
      new_successful: new_successful
    } do
      {:ok, %Payment{id: ^payment_id, status: ^new_status, successful: ^new_successful}} =
        Payments.update(payment_id, %{status: new_status, successful: new_successful})
    end

    test "with invalid status", %{payment: %{id: payment_id}} do
      {:error,
       %Changeset{
         errors: [
           {:status, {"is invalid", _detail}}
           | _tail
         ]
       }} = Payments.update(payment_id, %{status: :invalid})
    end
  end

  describe "retrieve_by_id/1" do
    test "when payment exist", %{payment: %{id: payment_id}} do
      {:ok, %Payment{id: ^payment_id}} = Payments.retrieve_by_id(payment_id)
    end

    test "when payment doesn't exist", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = Payments.retrieve_by_id(not_existing_uuid)
    end
  end

  describe "retrieve_outgoing_payments_by_address/1" do
    test "when address exist", %{source_account: %{id: source_account_id, address: address}} do
      {:ok, [%Payment{source_account_id: ^source_account_id}]} =
        Payments.retrieve_outgoing_payments_by_address(address)
    end

    test "when address doesn't exist" do
      {:ok, []} = Payments.retrieve_outgoing_payments_by_address("address")
    end
  end

  describe "retrieve_incoming_payments_by_address/1" do
    test "when address exist", %{
      destination_account: %{id: destination_account_id, address: address}
    } do
      {:ok, [%Payment{destination_account_id: ^destination_account_id}]} =
        Payments.retrieve_incoming_payments_by_address(address)
    end

    test "when address doesn't exist" do
      {:ok, []} = Payments.retrieve_incoming_payments_by_address("address")
    end
  end
end

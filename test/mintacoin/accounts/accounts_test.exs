defmodule Mintacoin.Accounts.AccountsTest do
  @moduledoc """
    This module is used to group common tests for Accounts functions
  """

  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox
  alias Mintacoin.{Account, Accounts, Accounts.StellarMock, BlockchainTx, BlockchainTxs}
  alias Mintacoin.Accounts.Workers.CreateAccount, as: CreateAccountWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    Application.put_env(:mintacoin, :crypto_impl, StellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)

    %{
      invalid_address: "INVALID_ADDRESS",
      not_found_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  test "create_db_record/1" do
    {:ok, %Account{}} = Accounts.create_db_record()
  end

  describe "retrieve_by_id/1" do
    test "with valid id" do
      %Account{id: id} = insert(:account)
      {:ok, %Account{id: ^id}} = Accounts.retrieve_by_id(id)
    end

    test "with non existing id", %{not_found_uuid: not_found_uuid} do
      {:ok, nil} = Accounts.retrieve_by_id(not_found_uuid)
    end
  end

  describe "retrieve_by_address/1" do
    test "with valid address" do
      %Account{address: address} = insert(:account)
      {:ok, %Account{address: ^address}} = Accounts.retrieve_by_address(address)
    end

    test "with non existing address", %{invalid_address: invalid_address} do
      {:ok, nil} = Accounts.retrieve_by_address(invalid_address)
    end
  end

  describe "recover_signature/2" do
    test "should return signature" do
      %Account{address: address, seed_words: seed_words, signature: signature} = insert(:account)

      {:ok, ^signature} = Accounts.recover_signature(address, seed_words)
    end

    test "with invalid seed words" do
      %Account{address: address} = insert(:account)

      {:error, :invalid_seed_words} =
        Accounts.recover_signature(
          address,
          "these are twelve really bad seed words for the account retrieve by"
        )
    end
  end

  describe "create/1" do
    setup do
      blockchain = insert(:blockchain, %{name: "stellar"})

      %{blockchain: blockchain}
    end

    test "enqueuing create account job", %{blockchain: blockchain} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, %Account{}} = Accounts.create(blockchain)

        assert_enqueued(
          worker: CreateAccountWorker,
          queue: :create_account_queue
        )
      end)
    end

    test "with valid params", %{blockchain: %{id: blockchain_id} = blockchain} do
      {:ok, %Account{id: account_id}} = Accounts.create(blockchain)

      {:ok, [blockchain_tx | _tail]} = BlockchainTxs.retrieve_by_account_id(account_id)

      %BlockchainTx{blockchain_id: ^blockchain_id, account_id: ^account_id} = blockchain_tx
    end
  end
end

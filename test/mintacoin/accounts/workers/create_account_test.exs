defmodule Mintacoin.Accounts.Workers.CreateAccountTest do
  @moduledoc """
  This module is used to test worker to create accounts in the blockchains
  """

  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox
  alias Mintacoin.{Accounts.Cipher, Accounts.StellarMock, BlockchainTx, BlockchainTxs}
  alias Mintacoin.Accounts.Workers.CreateAccount, as: CreateAccountWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    Application.put_env(:mintacoin, :crypto_impl, StellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)

    %{id: blockchain_id} = insert(:blockchain, name: "stellar")
    %{id: account_id, signature: signature} = insert(:account)
    {:ok, encrypted_signature} = Cipher.encrypt_with_system_key(signature)

    %{
      blockchain_id: blockchain_id,
      account_id: account_id,
      encrypted_signature: encrypted_signature
    }
  end

  test "crating new account", %{
    blockchain_id: blockchain_id,
    account_id: account_id,
    encrypted_signature: encrypted_signature
  } do
    {_status,
     %BlockchainTx{id: blockchain_tx_id, blockchain_id: ^blockchain_id, account_id: ^account_id}} =
      perform_job(CreateAccountWorker, %{
        blockchain_id: blockchain_id,
        account_id: account_id,
        encrypted_signature: encrypted_signature
      })

    {:ok, %BlockchainTx{id: ^blockchain_tx_id}} = BlockchainTxs.retrieve_by_id(blockchain_tx_id)
  end
end

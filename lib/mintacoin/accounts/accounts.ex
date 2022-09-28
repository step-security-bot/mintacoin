defmodule Mintacoin.Accounts do
  @moduledoc """
  This module is the responsible for the CRUD operations for accounts and also for the aggregate operations within the accounts context.
  """

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Account, Accounts.Cipher, Accounts.Keypair, Blockchain, Repo}
  alias Mintacoin.Accounts.Workers.CreateAccount, as: CreateAccountWorker

  @type id :: UUID.t()
  @type address :: String.t()
  @type seed_words :: String.t()
  @type signature :: String.t() | nil
  @type account :: Account.t() | nil
  @type error ::
          Changeset.t()
          | :decoding_error
          | :invalid_address
          | :invalid_seed_words
          | :encryption_error

  @spec create(Mintacoin.Blockchain.t()) :: {:ok, Account.t()} | {:error, error()}
  def create(%Blockchain{id: blockchain_id}) do
    with {:ok, %Account{id: account_id, signature: signature} = account} <- create_db_record(),
         {:ok, encrypted_signature} <- Cipher.encrypt_with_system_key(signature) do
      %{
        account_id: account_id,
        blockchain_id: blockchain_id,
        encrypted_signature: encrypted_signature
      }
      |> CreateAccountWorker.new()
      |> Oban.insert()

      {:ok, account}
    end
  end

  @spec create_db_record :: {:ok, Account.t()} | {:error, error()}
  def create_db_record do
    signature_fields = Keypair.build_signature_fields()

    %Account{}
    |> Account.create_changeset(signature_fields)
    |> Repo.insert()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, account()}
  def retrieve_by_id(id), do: {:ok, Repo.get(Account, id)}

  @spec retrieve_by_address(address :: address()) :: {:ok, account()}
  def retrieve_by_address(address), do: {:ok, Repo.get_by(Account, address: address)}

  @spec recover_signature(address :: address(), seed_words :: seed_words()) ::
          {:ok, signature()} | {:error, error()}
  def recover_signature(address, seed_words) do
    with {:ok, %Account{encrypted_signature: encrypted_signature}} <-
           retrieve_by_address(address),
         {:ok, entropy} <- Keypair.get_entropy_from_seed_words(seed_words) do
      Cipher.decrypt(encrypted_signature, entropy)
    else
      {:ok, nil} -> {:error, :invalid_address}
      error -> error
    end
  end
end

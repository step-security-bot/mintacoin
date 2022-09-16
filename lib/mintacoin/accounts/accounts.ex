defmodule Mintacoin.Accounts do
  @moduledoc """
  This module is the responsible for the CRUD operations for accounts and also for the aggreate operations within the accounts context.
  """

  alias Ecto.{Changeset, Multi}

  alias Mintacoin.{
    Account,
    Accounts.Cipher,
    Accounts.Keypair,
    Blockchain,
    Blockchains,
    BlockchainTx,
    BlockchainTxs,
    Repo
  }

  @type address :: String.t()
  @type seed_words :: String.t()
  @type signature :: String.t() | nil
  @type account :: Account.t() | nil
  @type params :: map()
  @type error :: Changeset.t() | :decoding_error | :invalid_address | :invalid_seed_words

  @spec create_account(params :: map()) :: {:ok, Account.t()} | {:error, error()}
  def create_account(params),
    do:
      Multi.new()
      |> Multi.run(:account, fn _repo, _ -> create() end)
      |> Multi.run(:blockchain_tx, create_blockchain_tx(params))
      |> Repo.transaction()
      |> handle_multi_response()

  @spec create :: {:ok, Account.t()} | {:error, error()}
  def create do
    signature_fields = Keypair.build_signature_fields()

    %Account{}
    |> Account.create_changeset(signature_fields)
    |> Repo.insert()
  end

  @spec retrieve(address :: address()) :: {:ok, account()}
  def retrieve(address), do: {:ok, Repo.get_by(Account, address: address)}

  @spec recover_signature(address :: address(), seed_words :: seed_words()) ::
          {:ok, signature()} | {:error, error()}
  def recover_signature(address, seed_words) do
    with {:ok, %Account{encrypted_signature: encrypted_signature}} <- retrieve(address),
         {:ok, entropy} <- Keypair.get_entropy_from_seed_words(seed_words) do
      Cipher.decrypt(encrypted_signature, entropy)
    else
      {:ok, nil} -> {:error, :invalid_address}
      error -> error
    end
  end

  @spec create_blockchain_tx(params :: params()) ::
          (any(), map() -> {:ok, BlockchainTx.t()} | {:error, error()})
  defp create_blockchain_tx(%{blockchain: blockchain, network: network}) do
    fn _repo, %{account: %Account{id: account_id}} ->
      case Blockchains.retrieve(blockchain, network) do
        {:ok, %Blockchain{id: blockchain_id}} ->
          BlockchainTxs.create(%{
            account_id: account_id,
            blockchain_id: blockchain_id
          })

        {:ok, nil} ->
          {:error, :invalid_blockchain}
      end
    end
  end

  @spec handle_multi_response(response :: tuple()) :: {:ok, Account.t()} | {:error, error()}
  defp handle_multi_response({:ok, %{account: account}}), do: {:ok, account}
  defp handle_multi_response({:error, _step, error, _result}), do: {:error, error}
end

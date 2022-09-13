defmodule Mintacoin.Accounts do
  @moduledoc """
  This module is the responsible for the CRUD operations for accounts and also for the aggreate operations within the accounts context.
  """

  alias Ecto.Changeset
  alias Mintacoin.{Account, Accounts.Cipher, Accounts.Keypair, Repo}

  @type address :: String.t()
  @type seed_words :: String.t()
  @type signature :: String.t() | nil
  @type parameter :: keyword()
  @type error ::
          Changeset.t()
          | :not_found
          | :decoding_error
          | :bad_argument
          | :invalid_address
          | :invalid_seed_words

  @spec create :: {:ok, Account.t()} | {:error, error()}
  def create do
    Keypair.build_signature_fields()
    |> (&Account.create_changeset(%Account{}, &1)).()
    |> Repo.insert()
  end

  @spec retrieve(address :: address()) :: {:ok, Account.t() | nil} | {:error, error()}
  def retrieve(address) when is_binary(address), do: {:ok, Repo.get_by(Account, address: address)}
  def retrieve(_address), do: {:error, :invalid_address}

  @spec recover_signature(address :: address(), seed_words :: seed_words()) ::
          {:ok, signature()} | {:error, error()}
  def recover_signature(address, seed_words) do
    with {:ok, %Account{encrypted_signature: encrypted_signature}} <- retrieve(address),
         {:ok, entropy} <- Keypair.get_entropy_from_seed_words(seed_words) do
      Cipher.decrypt(encrypted_signature, entropy)
    end
  end
end

defmodule Mintacoin.Accounts do
  @moduledoc """
  This module is the responsible for the CRUD operations for accounts and also for the aggreate operations within the accounts context.
  """

  alias Ecto.Changeset
  alias Mintacoin.{Account, Accounts.Cipher, Accounts.Keypair, Repo}

  @type address :: String.t()
  @type seed_words :: String.t()
  @type signature :: String.t() | nil
  @type account :: Account.t() | nil
  @type error :: Changeset.t() | :decoding_error | :invalid_address | :invalid_seed_words

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
end

defmodule Mintacoin.AccountFactory do
  @moduledoc """
  Allow the creation of accounts while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.{Account, Accounts.Cipher, Accounts.Keypair}

  defmacro __using__(_opts) do
    quote do
      @spec account_factory(attrs :: map()) :: Account.t()
      def account_factory(attrs) do
        {:ok, {signature, address}} = Keypair.random()

        account_address = Map.get(attrs, :address, address)
        account_signature = Map.get(attrs, :signature, signature)
        customer = Map.get(attrs, :customer, insert(:customer))

        {:ok, seed_words} = Keypair.build_seed_words()

        account_seed_words = Map.get(attrs, :seed_words, seed_words)

        {:ok, entropy} = Keypair.get_entropy_from_seed_words(account_seed_words)
        {:ok, encrypted_signature} = Cipher.encrypt(account_signature, entropy)

        account_encrypted_signature = Map.get(attrs, :encrypted_signature, encrypted_signature)

        %Account{
          id: UUID.generate(),
          address: account_address,
          encrypted_signature: account_encrypted_signature,
          signature: account_signature,
          seed_words: account_seed_words,
          customer: customer
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end

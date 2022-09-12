defmodule Mintacoin.Accounts.Keypair do
  @moduledoc """
  Exposes functions for working with Mintacoin's Keypairs.
  You can:
  - Generate and derive keypairs with the Ed25519 library.
  - Build seed words, and get the entropy from them with the Bip39 library.
  """

  alias Mintacoin.Accounts.Cipher

  @block_size 16
  @language :english

  @type seed_words :: String.t()
  @type entropy :: String.t()
  @type public_key :: String.t()
  @type secret_key :: String.t()
  @type keypair :: {secret_key(), public_key()}
  @type error :: :secret_key_error

  @spec random :: {:ok, keypair()}
  def random do
    Ed25519.generate_key_pair()
    |> encode_keypair()
  end

  @spec from_secret_key(secret_key :: secret_key()) :: {:ok, keypair()} | {:error, error()}
  def from_secret_key(secret_key) do
    secret_key
    |> Base.decode32!(padding: false)
    |> Ed25519.generate_key_pair()
    |> encode_keypair()
  rescue
    _error -> {:error, :secret_key_error}
  end

  @spec get_entropy_from_seed_words(seed_words :: seed_words()) ::
          {:ok, entropy()} | {:error, error()}
  def get_entropy_from_seed_words(seed_words) do
    mnemonic_list = String.split(seed_words)

    @language
    |> Bip39.get_words()
    |> (&Bip39.mnemonic_to_entropy(mnemonic_list, &1)).()
    |> Base.encode32(padding: false)
    |> (&{:ok, &1}).()
  rescue
    _error -> {:error, :mnemonic_seed_words_error}
  end

  @spec build_seed_words :: {:ok, seed_words()}
  def build_seed_words do
    raw_entropy = :crypto.strong_rand_bytes(@block_size)

    @language
    |> Bip39.get_words()
    |> (&Bip39.entropy_to_mnemonic(raw_entropy, &1)).()
    |> Enum.join(" ")
    |> (&{:ok, &1}).()
  end

  @spec build_signature_fields :: map()
  def build_signature_fields do
    {:ok, {signature, address}} = random()
    {:ok, seed_words} = build_seed_words()
    {:ok, entropy} = get_entropy_from_seed_words(seed_words)
    {:ok, encrypted_signature} = Cipher.encrypt(signature, entropy)

    %{
      address: address,
      encrypted_signature: encrypted_signature,
      seed_words: seed_words,
      signature: signature
    }
  end

  @spec encode_keypair(keypair :: keypair()) :: {:ok, keypair()}
  defp encode_keypair({secret_key, public_key}) do
    encoded_secret_key = Base.encode32(secret_key, padding: false)
    encoded_public_key = Base.encode32(public_key, padding: false)

    {:ok, {encoded_secret_key, encoded_public_key}}
  end
end

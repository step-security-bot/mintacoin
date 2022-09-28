defmodule Mintacoin.Accounts.KeypairTest do
  @moduledoc """
  This modules defines the test cases of the `Keypair` module.
  """

  use Mintacoin.DataCase

  alias Mintacoin.Accounts.{Cipher, Keypair}

  setup do
    %{
      public_key: "LKQCM5H2LLLJ6GDSUJ6PHOKUBNY4JMFITTCS3KGEOWWGLM7WDYOA",
      secret_key: "ZZ6XJLOIOOYFXKTBRBS6NSH63TXEG3RAUHPIW6KXSTMPVPZ5STQQ",
      seed_words: "ill goat follow firm atom cup intact unhappy tuition mandate appear uncover",
      entropy: "ODWIC2VLUDSGWXLHNLVDBYBKOY"
    }
  end

  describe "random/0" do
    test "should return a keypair with a public and secret key" do
      {:ok, {secret_key, public_key}} = Keypair.random()
      refute is_nil(public_key)
      refute is_nil(secret_key)
    end
  end

  describe "from_secret_key/1" do
    test "with a valid secret key, it should return the keypair with the right public key", %{
      public_key: pk,
      secret_key: sk
    } do
      {:ok, {^sk, ^pk}} = Keypair.from_secret_key(sk)
    end

    test "with an invalid secret key, it should return an error" do
      {:error, :secret_key_error} = Keypair.from_secret_key("invalid")
    end
  end

  describe "build_seed_words/0" do
    test "returns a random set of seed words" do
      {:ok, seed_words} = Keypair.build_seed_words()

      12 =
        seed_words
        |> String.split()
        |> Enum.count()
    end
  end

  describe "get_entropy_from_seed_words/1" do
    test "returns the entropy from the given seed words", %{
      seed_words: seed_words,
      entropy: entropy
    } do
      {:ok, ^entropy} = Keypair.get_entropy_from_seed_words(seed_words)
    end

    test "show error with invalid seed words" do
      {:error, :invalid_seed_words} = Keypair.get_entropy_from_seed_words("INVALID ENTRY")
    end
  end

  describe "build_signature_fields/0" do
    setup do: Keypair.build_signature_fields()

    test "returns signature fields", %{
      address: address,
      encrypted_signature: encrypted_signature,
      seed_words: seed_words,
      signature: signature
    } do
      refute is_nil(address)
      refute is_nil(encrypted_signature)
      refute is_nil(seed_words)
      refute is_nil(signature)
    end

    test "validate signature fields", %{
      address: address,
      seed_words: seed_words,
      encrypted_signature: encrypted_signature,
      signature: signature
    } do
      {:ok, entropy} = Keypair.get_entropy_from_seed_words(seed_words)
      {:ok, ^signature} = Cipher.decrypt(encrypted_signature, entropy)
      {:ok, {_secret, ^address}} = Keypair.from_secret_key(signature)
    end
  end
end

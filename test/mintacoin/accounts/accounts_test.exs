defmodule Mintacoin.Accounts.AccountsTest do
  @moduledoc """
    This module is used to group common tests for Accounts functions
  """

  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 1]

  alias Ecto.Adapters.SQL.Sandbox
  alias Mintacoin.{Account, Accounts}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    %{
      invalid_address: "INVALID_ADDRESS"
    }
  end

  describe "create/1" do
    setup do
      {:ok,
       %Account{
         id: id,
         address: address,
         encrypted_signature: encrypted_signature,
         signature: signature,
         seed_words: seed_words
       }} = Accounts.create()

      %{
        id: id,
        address: address,
        encrypted_signature: encrypted_signature,
        signature: signature,
        seed_words: seed_words
      }
    end

    test "with valid params", %{
      id: id,
      address: address,
      encrypted_signature: encrypted_signature,
      signature: signature,
      seed_words: seed_words
    } do
      assert is_binary(id)
      assert is_binary(address)
      assert is_binary(encrypted_signature)
      assert is_binary(signature)
      assert is_binary(seed_words)
    end

    test "is present in database", %{id: id} do
      %Account{id: ^id} = Repo.get(Account, id)
    end
  end

  describe "retrieve/1" do
    test "with valid address" do
      %Account{address: address} = insert(:account)
      {:ok, %Account{address: ^address}} = Accounts.retrieve(address)
    end

    test "with non existing address", %{invalid_address: invalid_address} do
      {:ok, nil} = Accounts.retrieve(invalid_address)
    end

    test "with no binary address" do
      {:error, :invalid_address} = Accounts.retrieve(123)
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
end

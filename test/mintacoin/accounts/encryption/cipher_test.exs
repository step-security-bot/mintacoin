defmodule Mintacoin.Accounts.CipherTest do
  @moduledoc """
  This modules defines the test cases of the `Cipher` module.
  """

  use Mintacoin.DataCase

  alias Mintacoin.Accounts.Cipher

  setup do
    %{
      secret_key: "ZZ6XJLOIOOYFXKTBRBS6NSH63TXEG3RAUHPIW6KXSTMPVPZ5STQQ",
      entropy: "ODWIC2VLUDSGWXLHNLVDBYBKOY"
    }
  end

  describe "encrypt/2" do
    test "with valid key of 32 bytes should return a ciphertext", %{secret_key: sk} do
      {:ok, _ciphertext} = Cipher.encrypt("test", sk)
    end

    test "with valid key of 16 bytes should return a ciphertext", %{entropy: entropy} do
      {:ok, _ciphertext} = Cipher.encrypt("test", entropy)
    end

    test "with invalid key should return an error" do
      {:error, :encryption_error} = Cipher.encrypt("test", "invalid")
    end
  end

  describe "decrypt/2" do
    test "with valid key of 32 bytes should return a plaintext", %{secret_key: sk} do
      {:ok, ciphertext} = Cipher.encrypt("test", sk)
      {:ok, "test"} = Cipher.decrypt(ciphertext, sk)
    end

    test "with valid key of 16 bytes should return a plaintext", %{entropy: entropy} do
      {:ok, ciphertext} = Cipher.encrypt("test", entropy)
      {:ok, "test"} = Cipher.decrypt(ciphertext, entropy)
    end

    test "with invalid key should return an error" do
      {:error, :decoding_error} = Cipher.decrypt("test", "invalid")
    end
  end
end

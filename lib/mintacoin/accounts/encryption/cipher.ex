defmodule Mintacoin.Accounts.Cipher do
  @moduledoc """
  This module provides encryption helper functions to encrypt and decrypt using :crypto erlang's module
  """

  @type ciphertext :: String.t()
  @type payload :: String.t()
  @type key :: String.t()
  @type error :: :decoding_error | :encryption_error

  @spec encrypt(payload :: payload(), key :: key()) ::
          {:ok, ciphertext()} | {:error, error()}
  def encrypt(payload, key) do
    {:ok, key} = Base.decode32(key, padding: false)
    {:ok, {block_size, cipher}} = detect_encryption_mode(key)

    iv = :crypto.strong_rand_bytes(16)
    plaintext = pad(payload, block_size)

    ciphertext =
      cipher
      |> :crypto.crypto_one_time(key, iv, plaintext, true)
      |> (&(iv <> &1)).()
      |> Base.encode64(padding: false)

    {:ok, ciphertext}
  rescue
    _error -> {:error, :encryption_error}
  end

  @spec decrypt(ciphertext :: ciphertext(), key :: key()) ::
          {:ok, payload()} | {:error, error()}
  def decrypt(ciphertext, key) do
    with {:ok, key} <- Base.decode32(key, padding: false),
         {:ok, <<iv::binary-16, ciphertext::binary>>} <-
           Base.decode64(ciphertext, padding: false),
         {:ok, {_block_size, cipher}} <- detect_encryption_mode(key) do
      plaintext =
        cipher
        |> :crypto.crypto_one_time(key, iv, ciphertext, false)
        |> unpad()

      {:ok, plaintext}
    else
      _error -> {:error, :decoding_error}
    end
  end

  @spec encrypt_with_system_key(payload :: payload()) :: {:ok, ciphertext()} | {:error, error()}
  def encrypt_with_system_key(payload) do
    encrypt(payload, system_encryption_secret())
  end

  @spec decrypt_with_system_key(ciphertext :: ciphertext()) ::
          {:ok, payload()} | {:error, error()}
  def decrypt_with_system_key(ciphertext) do
    decrypt(ciphertext, system_encryption_secret())
  end

  @spec system_encryption_secret() :: key()
  defp system_encryption_secret do
    Application.get_env(:mintacoin, :encryption_variable, nil)
  end

  @spec unpad(data :: String.t()) :: String.t()
  defp unpad(data) do
    to_remove = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - to_remove)
  end

  @spec pad(data :: String.t(), block_size :: integer()) :: String.t()
  defp pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> :binary.copy(<<to_add>>, to_add)
  end

  @spec detect_encryption_mode(key :: binary()) ::
          {:ok, {block_size :: integer(), cipher :: atom()}}
  defp detect_encryption_mode(key) do
    case block_size = byte_size(key) do
      16 -> {:ok, {block_size, :aes_128_cbc}}
      32 -> {:ok, {block_size, :aes_256_cbc}}
      _ -> {:error, :invalid_key_size}
    end
  end
end

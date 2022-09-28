defmodule Mintacoin.Accounts.Stellar do
  @moduledoc """
  Implementation of the Stellar crypto functions for accounts
  """

  alias Mintacoin.Accounts.Crypto.AccountResponse
  alias Stellar.{Horizon, Horizon.Transaction, KeyPair, TxBuild}

  @type status :: :ok | :error
  @type stellar_response :: map()
  @type public_key :: String.t()
  @type secret_key :: String.t()
  @type error :: {:error, any()}

  @behaviour Mintacoin.Accounts.Crypto.Spec

  @impl true
  def create_account(_opts) do
    {fund_public_key, _fund_private_key} = fund_keypair = fund_key_pair_from_system()
    {public_key, secret_key} = KeyPair.random()

    source_account = TxBuild.Account.new(fund_public_key)
    {:ok, seq_num} = Horizon.Accounts.fetch_next_sequence_number(fund_public_key)
    sequence_number = TxBuild.SequenceNumber.new(seq_num)

    operation =
      TxBuild.CreateAccount.new(
        destination: public_key,
        starting_balance: 1
      )

    signature = TxBuild.Signature.new(fund_keypair)

    {:ok, envelope} =
      source_account
      |> TxBuild.new(sequence_number: sequence_number)
      |> TxBuild.add_operation(operation)
      |> TxBuild.sign(signature)
      |> TxBuild.envelope()

    envelope
    |> Horizon.Transactions.create()
    |> format_response(public_key, secret_key)
  end

  @spec fund_key_pair_from_system() :: {public_key(), secret_key()}
  defp fund_key_pair_from_system do
    Application.get_env(:mintacoin, :stellar_fund_secret_key, nil)
    |> KeyPair.from_secret_seed()
  end

  @spec format_response(
          {status(), stellar_response()},
          public_key :: secret_key(),
          secret_key :: secret_key()
        ) :: {:ok, AccountResponse.t()} | error()
  defp format_response(
         {:ok,
          %Transaction{id: id, successful: successful, hash: hash, created_at: created_at} =
            tx_response},
         public_key,
         secret_key
       ) do
    {:ok,
     %AccountResponse{
       public_key: public_key,
       secret_key: secret_key,
       successful: successful,
       tx_id: id,
       tx_hash: hash,
       tx_timestamp: DateTime.to_string(created_at),
       tx_response: Map.from_struct(tx_response)
     }}
  end

  defp format_response({:error, response}, _public_key, _secret_key), do: {:error, response}
end

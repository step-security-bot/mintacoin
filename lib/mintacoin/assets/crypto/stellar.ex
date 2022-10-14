defmodule Mintacoin.Assets.Stellar do
  @moduledoc """
  Implementation of the Stellar crypto functions for assets
  """

  alias Mintacoin.Assets.Crypto.AssetResponse
  alias Stellar.{Horizon, Horizon.Transaction, KeyPair, TxBuild}
  alias Stellar.TxBuild.{ChangeTrust, Payment, Signature}

  @behaviour Mintacoin.Assets.Crypto.Spec

  @type account_information :: map()
  @type asset :: list()
  @type asset_code :: String.t()
  @type change_trust :: ChangeTrust.t()
  @type error :: {:error, any()}
  @type impl_response :: {:ok, AssetResponse.t()} | error()
  @type envelope :: String.t()
  @type key :: String.t()
  @type operation :: payment() | change_trust()
  @type operations :: list(operation())
  @type payment :: Payment.t()
  @type sequence_number :: struct()
  @type signatures :: list(Signature.t())
  @type status :: :ok | :error
  @type stellar_response :: map()
  @type supply :: integer() | float()
  @type tx_envelop :: {:ok, envelope()} | {:error, atom()}

  @impl true
  def create_asset(opts) do
    distributor_secret_key = Keyword.get(opts, :distributor_secret_key)
    asset_code = Keyword.get(opts, :asset_code)
    asset_supply = Keyword.get(opts, :asset_supply)

    %{
      public_key: issuer_public_key,
      signature: issuer_signature
    } = master_account_information()

    %{
      public_key: distributor_public_key,
      signature: distributor_signature
    } = account_information(distributor_secret_key)

    issuer_public_key
    |> build_asset_operations(distributor_public_key, asset_code, asset_supply)
    |> build_envelope(issuer_public_key, [issuer_signature, distributor_signature])
    |> execute_transaction()
  end

  @impl true
  def create_trustline(opts) do
    trustor_secret_key = Keyword.get(opts, :trustor_secret_key)
    asset_code = Keyword.get(opts, :asset_code)

    %{public_key: issuer_public_key} = master_account_information()

    %{
      public_key: trustor_public_key,
      signature: trustor_signature
    } = account_information(trustor_secret_key)

    issuer_public_key
    |> build_trustline_operation(asset_code)
    |> build_envelope(trustor_public_key, trustor_signature)
    |> execute_transaction()
  end

  @spec execute_transaction(tx_envelop :: tx_envelop()) :: impl_response()
  defp execute_transaction({:ok, envelope}) do
    envelope
    |> Horizon.Transactions.create()
    |> format_response()
  end

  @spec build_envelope(
          operations :: operations(),
          source_account_pk :: key(),
          signatures :: signatures()
        ) :: tx_envelop()
  defp build_envelope(operations, source_account_pk, signatures) do
    sequence_number = get_sequence_number(source_account_pk)

    source_account_pk
    |> TxBuild.Account.new()
    |> Stellar.TxBuild.new(sequence_number: sequence_number)
    |> TxBuild.add_operations(operations)
    |> TxBuild.sign(signatures)
    |> TxBuild.envelope()
  end

  @spec get_sequence_number(public_key :: key()) :: sequence_number()
  defp get_sequence_number(public_key) do
    {:ok, seq_num} = Horizon.Accounts.fetch_next_sequence_number(public_key)
    TxBuild.SequenceNumber.new(seq_num)
  end

  @spec build_asset_operations(
          issuer_pk :: key(),
          distributor_pk :: key(),
          asset_code :: asset_code(),
          supply :: supply()
        ) :: operations()
  defp build_asset_operations(issuer_pk, distributor_pk, asset_code, supply) do
    asset = [code: asset_code, issuer: issuer_pk]

    [
      trustline_operation(asset, distributor_pk),
      payment_operation(distributor_pk, asset, supply, issuer_pk)
    ]
  end

  @spec build_trustline_operation(issuer_pk :: key(), asset_code :: asset_code()) :: operations()
  defp build_trustline_operation(issuer_pk, asset_code) do
    asset = [code: asset_code, issuer: issuer_pk]

    [trustline_operation(asset, nil)]
  end

  @spec trustline_operation(asset :: asset(), distributor_pk :: key() | nil) :: change_trust()
  defp trustline_operation(asset, distributor_pk) do
    TxBuild.ChangeTrust.new(
      asset: asset,
      source_account: distributor_pk
    )
  end

  @spec payment_operation(
          destination_pk :: key(),
          asset :: asset(),
          amount :: supply(),
          source_pk :: key()
        ) :: payment()
  defp payment_operation(destination_pk, asset, amount, source_pk) do
    TxBuild.Payment.new(
      destination: destination_pk,
      asset: asset,
      amount: amount,
      source_account: source_pk
    )
  end

  @spec account_information(secret_key :: key()) :: account_information()
  defp account_information(secret_key) do
    {pk, _sk} = account_keypair = KeyPair.from_secret_seed(secret_key)
    signature = TxBuild.Signature.new(account_keypair)

    %{
      public_key: pk,
      signature: signature
    }
  end

  @spec master_account_information() :: account_information()
  defp master_account_information, do: master_account_secret_key() |> account_information()

  @spec master_account_secret_key() :: key() | nil
  defp master_account_secret_key, do: Application.get_env(:mintacoin, :stellar_fund_secret_key)

  @spec format_response(tx_response :: {status(), stellar_response()}) :: impl_response()
  defp format_response(
         {:ok,
          %Transaction{id: id, successful: successful, hash: hash, created_at: created_at} =
            tx_response}
       ) do
    {:ok,
     %AssetResponse{
       successful: successful,
       tx_id: id,
       tx_hash: hash,
       tx_timestamp: DateTime.to_string(created_at),
       tx_response: Map.from_struct(tx_response)
     }}
  end

  defp format_response({:error, response}), do: {:error, response}
end

defmodule MintacoinWeb.PaymentsController do
  @moduledoc """
  This module contains the payment endpoints
  """

  use MintacoinWeb, :controller

  alias Ecto.UUID

  alias Mintacoin.{
    Asset,
    Assets,
    Blockchain,
    Blockchains,
    Payment,
    Payments,
    Wallet,
    Wallets
  }

  @type address :: String.t()
  @type asset :: Asset.t()
  @type blockchain :: Blockchain.t()
  @type blockchain_name :: String.t()
  @type conn :: Plug.Conn.t()
  @type id :: UUID.t()
  @type network :: :testnet | :mainnet
  @type params :: map()
  @type payment :: Payment.t()
  @type resource :: Payment.t()
  @type response_status :: :created
  @type status :: :ok | :error
  @type template :: String.t()
  @type wallet :: Wallet.t()
  @type error ::
          :blockchain_not_found
          | :invalid_supply_format
          | :decoding_error
          | :bad_request
          | :asset_not_found
          | :wallet_not_found
          | :insufficient_funds
          | :destination_trustline_not_found
          | :source_balance_not_found

  action_fallback MintacoinWeb.FallbackController

  @default_blockchain_name Blockchain.default()

  @spec create(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def create(
        %{assigns: %{network: network}} = conn,
        %{
          "source_signature" => _source_signature,
          "source_address" => source_address,
          "destination_address" => destination_address,
          "amount" => _amount,
          "asset_id" => asset_id
        } = params
      ) do
    blockchain_name = Map.get(params, "blockchain", @default_blockchain_name)

    with {:ok, %Asset{}} <- retrieve_asset(asset_id),
         {:ok, %Blockchain{id: blockchain_id}} <-
           retrieve_blockchain(blockchain_name, network),
         {:ok, %Wallet{account_id: source_account_id}} <-
           retrieve_wallet(blockchain_id, source_address),
         {:ok, %Wallet{account_id: destination_account_id}} <-
           retrieve_wallet(blockchain_id, destination_address) do
      source_account_id
      |> create_payment(destination_account_id, blockchain_id, params)
      |> handle_response(conn, :created, "payment.json")
    end
  end

  @spec retrieve_asset(asset_id :: id()) :: {:ok, asset()} | {:error, error()}
  defp retrieve_asset(asset_id) do
    case Assets.retrieve_by_id(asset_id) do
      {:ok, %Asset{} = asset} -> {:ok, asset}
      _any -> {:error, :asset_not_found}
    end
  end

  @spec retrieve_blockchain(blockchain_name :: blockchain_name(), network :: network()) ::
          {:ok, blockchain()} | {:error, error()}
  defp retrieve_blockchain(blockchain, network) do
    case Blockchains.retrieve(blockchain, network) do
      {:ok, %Blockchain{} = blockchain} -> {:ok, blockchain}
      _any -> {:error, :blockchain_not_found}
    end
  end

  @spec retrieve_wallet(
          blockchain_id :: id(),
          address :: address()
        ) :: {:ok, wallet()} | {:error, error()}
  defp retrieve_wallet(blockchain_id, address) do
    case Wallets.retrieve_by_account_address_and_blockchain_id(address, blockchain_id) do
      {:ok, %Wallet{} = wallet} -> {:ok, wallet}
      _any -> {:error, :wallet_not_found}
    end
  end

  @spec create_payment(
          source_account_id :: id(),
          destination_account_id :: id(),
          blockchain_id :: id(),
          params :: params()
        ) ::
          payment :: {:ok, payment()} | {:error, error}
  defp create_payment(
         source_account_id,
         destination_account_id,
         blockchain_id,
         %{
           "source_signature" => source_signature,
           "amount" => amount,
           "asset_id" => asset_id
         }
       ) do
    Payments.create(%{
      source_signature: source_signature,
      source_account_id: source_account_id,
      destination_account_id: destination_account_id,
      blockchain_id: blockchain_id,
      asset_id: asset_id,
      amount: amount
    })
  end

  @spec handle_response(
          resource :: {:ok, resource()} | {:error, error()},
          conn :: conn(),
          status :: response_status(),
          template :: template()
        ) :: conn() | {:error, error()}
  defp handle_response({:ok, resource}, conn, status, template) do
    conn
    |> put_status(status)
    |> render(template, resource: resource)
  end

  defp handle_response({:error, error}, _conn, _status, _template), do: {:error, error}
end

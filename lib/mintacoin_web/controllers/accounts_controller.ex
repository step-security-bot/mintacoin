defmodule MintacoinWeb.AccountsController do
  @moduledoc """
  This module contains the account endpoints
  """

  use MintacoinWeb, :controller

  alias Ecto.Changeset
  alias Mintacoin.{Account, Accounts, Blockchain, Blockchains}

  @type params :: map()
  @type conn :: Plug.Conn.t()
  @type status :: :ok | :error
  @type response_status :: :ok | :created
  @type template :: String.t()
  @type response :: Account.t() | String.t() | nil
  @type error :: :not_found | :bad_request | Changeset.t()
  @type blockchain :: Blockchain.t() | nil

  action_fallback MintacoinWeb.FallbackController

  @errors %{
    blockchain_not_found: {400, "The introduced blockchain doesn't exist"},
    decoding_error: {400, "Address or seed words are invalid"},
    invalid_address: {400, "The address is invalid"},
    invalid_seed_words: {400, "The seed words are invalid"},
    encryption_error: {400, "Error during encryption"}
  }

  @spec create(conn :: conn(), params :: params()) :: conn() | {:error, error()}
  def create(%{assigns: %{network: network}} = conn, %{"blockchain" => blockchain}) do
    blockchain
    |> Blockchains.retrieve(network)
    |> create_account()
    |> handle_response(conn, :created, "account.json")
  end

  def create(_conn, _params), do: {:error, :bad_request}

  @spec recover(conn :: conn(), params :: params()) :: {:ok, response()} | {:error, error()}
  def recover(conn, %{"address" => address, "seed_words" => seed_words}) do
    address
    |> Accounts.recover_signature(seed_words)
    |> handle_response(conn, :ok, "signature.json")
  end

  def recover(_conn, _params), do: {:error, :bad_request}

  @spec create_account({:ok, blockchain()}) :: {status(), response()}
  defp create_account({:ok, %Blockchain{} = blockchain}), do: Accounts.create(blockchain)
  defp create_account({:ok, nil}), do: {:error, :blockchain_not_found}

  @spec handle_response(
          {:ok, response :: response()},
          conn :: conn(),
          status :: response_status(),
          template :: template()
        ) :: conn()
  defp handle_response({:ok, resource}, conn, status, template) do
    conn
    |> put_status(status)
    |> render(template, resource: resource)
  end

  defp handle_response({:error, resource}, _conn, _status, _template) do
    {status, message} = Map.get(@errors, resource, {400, "Accounts Controller Error"})

    {:error, %{status: status, detail: message, code: resource}}
  end
end

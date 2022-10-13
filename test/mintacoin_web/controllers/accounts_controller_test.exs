defmodule MintacoinWeb.AccountsControllerTest do
  @moduledoc """
  This module is used to test account's endpoints
  """

  use MintacoinWeb.ConnCase
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 2]

  alias Mintacoin.Accounts.StellarMock

  setup %{conn: conn} do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)

    address = "GB3ZYW3WZWQU6CAEA6EQ4ALER456DPVBC6YLQRDKTTSNEVJOGFCECX5L"
    signature = "SB3RAKL2MRYZ53WJQAL5RJ42LPCMJTNDH4W7UWVRJA3GTEC66BC7VNUT"

    blockchain = insert(:blockchain, %{name: "stellar", network: "testnet"})
    account = insert(:account, %{address: address, signature: signature})

    %{
      account: account,
      address: address,
      signature: signature,
      blockchain: blockchain,
      conn: put_req_header(conn, "accept", "application/json")
    }
  end

  describe "create/2" do
    test "with valid params", %{conn: conn, blockchain: %{name: blockchain_name}} do
      conn = post(conn, Routes.accounts_path(conn, :create), %{blockchain: blockchain_name})

      %{
        "data" => %{
          "address" => _address,
          "signature" => _signature,
          "seed_words" => _seed_words
        },
        "status" => 201
      } = json_response(conn, 201)
    end

    test "when blockchain is not valid", %{conn: conn} do
      conn = post(conn, Routes.accounts_path(conn, :create), %{blockchain: "INVALID"})

      %{
        "code" => "blockchain_not_found",
        "detail" => "The introduced blockchain doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when blockchain is not present", %{conn: conn} do
      conn = post(conn, Routes.accounts_path(conn, :create))

      json_response(conn, 400)
    end
  end

  describe "recover/2" do
    test "when params are valid", %{
      conn: conn,
      address: address,
      account: %{signature: signature, seed_words: seed_words}
    } do
      conn = post(conn, Routes.accounts_path(conn, :recover, address), %{seed_words: seed_words})

      %{"data" => %{"signature" => ^signature}, "status" => 200} = json_response(conn, 200)
    end

    test "when address is invalid", %{conn: conn, account: %{seed_words: seed_words}} do
      conn =
        post(conn, Routes.accounts_path(conn, :recover, "INVALID_ADDRESS"), %{
          seed_words: seed_words
        })

      %{"code" => "invalid_address", "detail" => "The address is invalid", "status" => 400} =
        json_response(conn, 400)
    end

    test "when seed_words is invalid", %{conn: conn, address: address} do
      conn =
        post(conn, Routes.accounts_path(conn, :recover, address), %{
          seed_words: "INVALID_SEED_WORDS"
        })

      %{
        "code" => "invalid_seed_words",
        "detail" => "The seed words are invalid",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when seed_words are not present", %{conn: conn, address: address} do
      conn = post(conn, Routes.accounts_path(conn, :recover, address))

      json_response(conn, 400)
    end
  end
end

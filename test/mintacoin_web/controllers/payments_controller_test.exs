defmodule MintacoinWeb.PaymentsControllerTest do
  @moduledoc """
  This module is used to test payments's endpoints
  """

  use MintacoinWeb.ConnCase
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Mintacoin.{Accounts.Cipher, Payment, Payments, Payments.StellarMock}

  setup %{conn: conn} do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)

    blockchain = insert(:blockchain, %{name: "stellar", network: "testnet"})

    source_account =
      insert(:account, %{
        address: "F7NJQPUN2ZFQTSGQWJ44NKBMEBQU3TEWS4ADL5SX32ZEGR2C5MUA",
        signature: "336XNTQP3W4MRAYNBYVRL2OKFSNBWR574OC4PKB3KYPCXALTUGHA"
      })

    destination_account =
      insert(:account, %{
        address: "XN5BDEMCLMDYDD6UTG2ZM26UGX6BF6VMN3VR23BKISOOZT7TEJEQ",
        signature: "WZTTQ2B42QBTXJU5ZOTZUSF72V7E55BMBTGDOLY5W5NW6T3U7S6Q"
      })

    api_token = Application.get_env(:mintacoin, :api_token)

    conn_authenticated =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_token}")

    conn_invalid_token =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer INVALID_TOKEN")

    %{
      source_account: source_account,
      destination_account: destination_account,
      blockchain: blockchain,
      conn_authenticated: conn_authenticated,
      conn_unauthenticated: put_req_header(conn, "accept", "application/json"),
      conn_invalid_token: conn_invalid_token,
      not_existing_uuid: "49354685-d6c7-4c4e-81fe-6144ab3122fa"
    }
  end

  describe "create/2" do
    setup [
      :create_asset,
      :create_source_data,
      :create_source_trustline,
      :create_destination_data,
      :create_destination_trustline
    ]

    test "with valid params", %{
      conn_authenticated: conn,
      source_account: %{id: source_id, address: source_address, signature: source_signature},
      destination_account: %{id: destination_id, address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "data" => %{
          "payment_id" => payment_id
        },
        "status" => 201
      } = json_response(conn, 201)

      {:ok, %Payment{source_account_id: ^source_id, destination_account_id: ^destination_id}} =
        Payments.retrieve_by_id(payment_id)
    end

    test "with invalid source address", %{
      conn_authenticated: conn,
      source_account: %{signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: "NTYVZN3ZNFFFPOCPKTFY3TPPOYMVYR53JHRWYNW3DIDMWC7AGF5Q",
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => "wallet_not_found",
        "detail" =>
          "The introduced address doesn't exist or doesn't have associated the blockchain",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "with invalid destination address", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: "NTYVZN3ZNFFFPOCPKTFY3TPPOYMVYR53JHRWYNW3DIDMWC7AGF5Q",
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => "wallet_not_found",
        "detail" =>
          "The introduced address doesn't exist or doesn't have associated the blockchain",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "with invalid source signature", %{
      conn_authenticated: conn,
      source_account: %{address: source_address},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: "NTYVZN3ZNFFFPOCPKTFY3TPPOYMVYR53JHRWYNW3DIDM",
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => "decoding_error",
        "detail" => "The signature is invalid",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "with invalid asset id", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      not_existing_uuid: not_existing_uuid
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: not_existing_uuid
        })

      %{
        "code" => "asset_not_found",
        "detail" => "The introduced asset doesn't exist",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "with invalid amount format", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: "34ABC",
          asset_id: asset_id
        })

      %{
        "code" => "invalid_supply_format",
        "detail" => "The introduced supply format is invalid",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when the balance of the source account is insufficient", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 20_000,
          asset_id: asset_id
        })

      %{
        "code" => "insufficient_funds",
        "detail" => "The source account doesn't have enough funds to make the payment",
        "status" => 400
      } = json_response(conn, 400)
    end

    test "when authenticate token is invalid", %{
      conn_invalid_token: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => 401,
        "detail" => "Invalid authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end

    test "when authenticate token is not submit", %{
      conn_unauthenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => 401,
        "detail" => "Missing authorization Bearer token",
        "status" => "unauthorized"
      } = json_response(conn, 401)
    end
  end

  describe "create/1 when the destination doesn't have a trustline with the asset" do
    setup [
      :create_asset,
      :create_source_data,
      :create_source_trustline,
      :create_destination_data
    ]

    test "with valid params", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => "destination_trustline_not_found",
        "detail" => "The destination account doesn't have a trustline with the asset",
        "status" => 400
      } = json_response(conn, 400)
    end
  end

  describe "create/1 when the destination doesn't have a wallet in the blockchain" do
    setup [
      :create_asset,
      :create_source_data,
      :create_source_trustline
    ]

    test "with valid params", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => "wallet_not_found",
        "detail" =>
          "The introduced address doesn't exist or doesn't have associated the blockchain",
        "status" => 400
      } = json_response(conn, 400)
    end
  end

  describe "create/1 when the source doesn't have a trustline with the asset" do
    setup [
      :create_asset,
      :create_source_data,
      :create_destination_data,
      :create_destination_trustline
    ]

    test "with valid params", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => "source_balance_not_found",
        "detail" => "The source account doesn't have a balance of the given asset",
        "status" => 400
      } = json_response(conn, 400)
    end
  end

  describe "create/1 when the source doesn't have a wallet in the blockchain" do
    setup [
      :create_asset,
      :create_destination_data,
      :create_destination_trustline
    ]

    test "with valid params", %{
      conn_authenticated: conn,
      source_account: %{address: source_address, signature: source_signature},
      destination_account: %{address: destination_address},
      asset: %{id: asset_id}
    } do
      conn =
        post(conn, Routes.payments_path(conn, :create), %{
          source_signature: source_signature,
          source_address: source_address,
          destination_address: destination_address,
          amount: 60,
          asset_id: asset_id
        })

      %{
        "code" => "wallet_not_found",
        "detail" =>
          "The introduced address doesn't exist or doesn't have associated the blockchain",
        "status" => 400
      } = json_response(conn, 400)
    end
  end

  defp create_asset(%{blockchain: blockchain}) do
    asset_code = "MTK"
    supply = "10000"

    %{signature: signature} = account = insert(:account)

    secret_key = "SBJCNL6H5WFDK2CUAWU2IAWGWQLGER77URPYXUJ5B4N4GY2HNEBL5JJG"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    asset = insert(:asset, %{code: asset_code, supply: supply})

    insert(:asset_holder, %{
      asset: asset,
      blockchain: blockchain,
      account: account,
      wallet: wallet
    })

    %{
      asset: asset,
      blockchain: blockchain
    }
  end

  defp create_source_data(%{
         source_account: source_account,
         blockchain: blockchain
       }) do
    wallet =
      insert(:wallet, %{
        account: source_account,
        blockchain: blockchain
      })

    %{source_wallet: wallet}
  end

  defp create_source_trustline(%{
         blockchain: blockchain,
         source_account: source_account,
         source_wallet: source_wallet,
         asset: asset
       }) do
    insert(:asset_holder, %{
      asset: asset,
      blockchain: blockchain,
      account: source_account,
      wallet: source_wallet
    })

    balance =
      insert(:balance, %{
        balance: "10000",
        asset: asset,
        wallet: source_wallet
      })

    %{source_balance: balance}
  end

  defp create_destination_data(%{
         destination_account: destination_account,
         blockchain: blockchain
       }) do
    wallet =
      insert(:wallet, %{
        account: destination_account,
        blockchain: blockchain
      })

    %{destination_wallet: wallet}
  end

  defp create_destination_trustline(%{
         blockchain: blockchain,
         destination_account: destination_account,
         destination_wallet: destination_wallet,
         asset: asset
       }) do
    insert(:asset_holder, %{
      asset: asset,
      blockchain: blockchain,
      account: destination_account,
      wallet: destination_wallet
    })

    balance =
      insert(:balance, %{
        balance: "10000",
        asset: asset,
        wallet: destination_wallet
      })

    %{destination_balance: balance}
  end
end

defmodule MintacoinWeb.Plugs.VerifyApiToken do
  @moduledoc """
  Plug to verify the current api token for all requests
  """
  @behaviour Plug

  import Plug.Conn, only: [put_status: 2, halt: 1, get_req_header: 2]
  import Phoenix.Controller, only: [put_view: 2, render: 3]
  alias MintacoinWeb.ErrorView

  @type conn :: Plug.Conn.t()
  @type status :: boolean()
  @type token :: binary() | nil

  @impl true
  def init(default), do: default

  @impl true
  def call(conn, _default) do
    basic_token = get_token(conn)
    valid_token = Application.get_env(:mintacoin, :api_token)

    resolve_authentication(basic_token, valid_token, conn)
  end

  @spec resolve_authentication(token :: token(), token :: token(), conn :: conn()) :: conn()
  defp resolve_authentication(token, token, conn), do: conn

  defp resolve_authentication(nil, _token, conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render("401.json", %{message: "Missing authentication token"})
    |> halt()
  end

  defp resolve_authentication(_request_token, _token, conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render("401.json", %{message: "Invalid authentication token"})
    |> halt()
  end

  @spec get_token(conn :: conn()) :: token()
  defp get_token(conn) do
    case get_req_header(conn, "auth-token") do
      [token] -> token
      _header -> nil
    end
  end
end

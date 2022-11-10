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
  def call(%{path_info: ["v1-alpha"]} = conn, _opts), do: conn

  @impl true
  def call(conn, _default) do
    basic_token = get_token(conn)
    valid_token = Application.get_env(:mintacoin, :api_token)

    resolve_authorization(basic_token, valid_token, conn)
  end

  @spec resolve_authorization(token :: token(), token :: token(), conn :: conn()) :: conn()
  defp resolve_authorization(token, token, conn), do: conn

  defp resolve_authorization(nil, _token, conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render("401.json", %{message: "Missing authorization Bearer token"})
    |> halt()
  end

  defp resolve_authorization(_request_token, _token, conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render("401.json", %{message: "Invalid authorization Bearer token"})
    |> halt()
  end

  @spec get_token(conn :: conn()) :: token()
  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _header -> nil
    end
  end
end

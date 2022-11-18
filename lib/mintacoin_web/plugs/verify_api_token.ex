defmodule MintacoinWeb.Plugs.VerifyApiToken do
  @moduledoc """
  Plug to verify the current api token for all requests
  """
  @behaviour Plug

  import Plug.Conn, only: [put_status: 2, halt: 1, get_req_header: 2, assign: 3]
  import Phoenix.Controller, only: [put_view: 2, render: 3]
  alias Ecto.UUID
  alias Mintacoin.{Customer, Customers}
  alias MintacoinWeb.ErrorView

  @type id :: UUID.t()
  @type conn :: Plug.Conn.t()
  @type status :: boolean()
  @type token :: binary() | nil
  @type error :: :invalid | :missing

  @impl true
  def init(default), do: default

  @impl true
  def call(%{path_info: ["v1-alpha"]} = conn, _opts), do: conn

  @impl true
  def call(conn, _default) do
    conn
    |> get_token
    |> Customers.verify_customer()
    |> validate_customer()
    |> resolve_authorization(conn)
  end

  @spec validate_customer(params :: tuple()) :: {:ok, id()} | {:error, error()}
  defp validate_customer({:ok, %{customer_id: customer_id}}) do
    case Customers.retrieve_by_id(customer_id) do
      {:ok, nil} -> {:error, :invalid}
      {:ok, %Customer{}} -> {:ok, customer_id}
    end
  end

  defp validate_customer({:error, response}), do: {:error, response}

  @spec resolve_authorization(params :: tuple(), conn :: conn()) :: conn()
  defp resolve_authorization({:ok, customer_id}, conn),
    do: assign(conn, :customer_id, customer_id)

  defp resolve_authorization({:error, :invalid}, conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render("401.json", %{message: "Invalid authorization Bearer token"})
    |> halt()
  end

  defp resolve_authorization({:error, :missing}, conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ErrorView)
    |> render("401.json", %{message: "Missing authorization Bearer token"})
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

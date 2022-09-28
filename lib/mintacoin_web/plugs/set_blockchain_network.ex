defmodule MintacoinWeb.Plugs.SetBlockchainNetwork do
  @moduledoc """
  Plug to add the current blockchain network to the conn
  """
  @behaviour Plug

  import Plug.Conn, only: [assign: 3]

  @impl true
  def init(default), do: default

  @impl true
  def call(conn, _default) do
    network = Application.get_env(:mintacoin, :blockchains_network, :testnet)
    assign(conn, :network, network)
  end
end

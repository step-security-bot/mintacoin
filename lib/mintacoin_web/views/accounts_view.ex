defmodule MintacoinWeb.AccountsView do
  @moduledoc """
  This module contains the JSON response for the account's endpoints
  """

  use MintacoinWeb, :view

  alias Mintacoin.Account

  @type template :: String.t()
  @type assigns :: map()
  @type json :: map()

  @spec render(template :: template(), assigns :: assigns()) :: json()
  def render("account.json", %{
        resource: %Account{address: address, signature: signature, seed_words: seed_words}
      }),
      do: %{status: 201, data: %{address: address, signature: signature, seed_words: seed_words}}

  def render("signature.json", %{resource: signature}),
    do: %{status: 200, data: %{signature: signature}}

  def render("error.json", %{error: %{status: status, code: code, detail: detail}}),
    do: %{status: status, code: code, detail: detail}
end

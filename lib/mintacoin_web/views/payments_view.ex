defmodule MintacoinWeb.PaymentsView do
  @moduledoc """
  This module contains the JSON response for the asset's endpoints
  """

  alias Mintacoin.Payment

  @type template :: String.t()
  @type assigns :: map()
  @type json :: map()

  @spec render(template :: template(), assigns :: assigns()) :: json()
  def render("payment.json", %{resource: %Payment{id: payment_id}}),
    do: %{status: 201, data: %{payment_id: payment_id}}
end

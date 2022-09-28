defmodule Mintacoin.Accounts.Crypto.Spec do
  @moduledoc """
  Defines contracts for the transactions available for accounts crypto
  """

  alias Mintacoin.Accounts.Crypto.AccountResponse

  @type opts :: Keyword.t()
  @type response :: {:ok, AccountResponse.t()} | {:error, map()}

  @callback create_account(opts()) :: response()
end

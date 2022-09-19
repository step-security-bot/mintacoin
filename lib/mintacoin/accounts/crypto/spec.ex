defmodule Mintacoin.Accounts.Crypto.Spec do
  @moduledoc """
  Defines contracts for the transactions available for accounts crypto
  """

  @type status :: :ok | :error
  @type params :: map()
  @type response :: map()
  @type opts :: Keyword.t()

  @callback create_account(params(), opts()) :: {status(), response()}
end

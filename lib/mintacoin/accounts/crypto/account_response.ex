defmodule Mintacoin.Accounts.Crypto.AccountResponse do
  @moduledoc """
  This struct defines the normalized response of a transaction when an account is created in a blockchain
  """

  @type t :: %__MODULE__{
          public_key: String.t(),
          secret_key: String.t(),
          successful: boolean(),
          tx_id: String.t(),
          tx_hash: String.t(),
          tx_timestamp: String.t(),
          tx_response: map()
        }

  defstruct [:public_key, :secret_key, :successful, :tx_id, :tx_hash, :tx_timestamp, :tx_response]
end

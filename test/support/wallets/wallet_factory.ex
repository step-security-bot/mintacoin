defmodule Mintacoin.WalletFactory do
  @moduledoc """
  Allow the creation of wallets while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.{Accounts.Cipher, Wallet}

  defmacro __using__(_opts) do
    quote do
      @spec wallet_factory(attrs :: map()) :: Wallet.t()
      def wallet_factory(attrs) do
        default_public_key =
          sequence(
            :public_key,
            &"UE5FYDVAPAEGYYMPJOY4Q54WB53YNX7XU6HIUDWTDYGO3WVDVY4Q#{&1}"
          )

        default_sk = "72ILTELXNGKM5Y23A74P3B67LJBHRQE4GOP43XIKETOFZQGNTEKA"

        %{signature: signature} = account = Map.get(attrs, :account, insert(:account))
        blockchain = Map.get(attrs, :blockchain, insert(:blockchain))
        public_key = Map.get(attrs, :public_key, default_public_key)
        secret_key = Map.get(attrs, :secret_key, default_sk)

        {:ok, default_encrypted_sk} = Cipher.encrypt(secret_key, signature)

        encrypted_secret_key = Map.get(attrs, :encrypted_secret_key, default_encrypted_sk)

        %Wallet{
          id: UUID.generate(),
          public_key: public_key,
          encrypted_secret_key: encrypted_secret_key,
          secret_key: secret_key,
          account: account,
          blockchain: blockchain
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end

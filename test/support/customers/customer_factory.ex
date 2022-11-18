defmodule Mintacoin.CustomerFactory do
  @moduledoc """
  Allow the creation of Customer while testing.
  """

  alias Ecto.UUID
  alias Mintacoin.{Accounts.Cipher, Customer}
  alias Phoenix.Token

  defmacro __using__(_opts) do
    quote do
      @spec customer_factory(attrs :: map()) :: Customer.t()
      def customer_factory(attrs) do
        id = UUID.generate()
        secret_key_base = Application.get_env(:mintacoin, :secret_key_base)
        signing_salt = Application.get_env(:mintacoin, :signing_salt)

        default_api_key =
          Token.sign(secret_key_base, signing_salt, %{customer_id: id}, max_age: 60)

        {:ok, default_encrypted_api_key} = Cipher.encrypt_with_system_key(default_api_key)

        name = Map.get(attrs, :name, "Customer")
        email = Map.get(attrs, :email, sequence(:email, &"customer_#{&1}@mintacoin.co"))
        api_key = Map.get(attrs, :api_key, default_api_key)
        encrypted_api_key = Map.get(attrs, :encrypted_api_key, default_encrypted_api_key)

        %Customer{
          id: id,
          email: email,
          name: name,
          api_key: api_key,
          encrypted_api_key: encrypted_api_key
        }
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end
    end
  end
end

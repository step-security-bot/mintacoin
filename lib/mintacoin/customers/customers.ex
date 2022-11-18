defmodule Mintacoin.Customers do
  @moduledoc """
  This module is the responsible to manege to customers authentication
  """

  alias Phoenix.Token
  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Accounts.Cipher, Customer, Repo}

  @type id :: UUID.t()
  @type customer :: Customer.t()
  @type params :: map()
  @type secrets :: {String.t(), String.t()}
  @type token :: String.t()
  @type token_age :: integer()
  @type token_data :: map()
  @type error :: :expired | :invalid | :missing | :encryption_error | Changeset.t()

  # 100 (days) * 24 (hours) * 3600 (sec)
  @token_age 8_640_000

  @spec create(params :: params()) :: {:ok, customer()} | {:error, error()}
  def create(%{email: email, name: name}) do
    id = Ecto.UUID.generate()
    {sign_token, encrypted_token} = generate_encrypted_token(id)

    changeset = %{
      id: id,
      email: email,
      name: name,
      encrypted_api_key: encrypted_token,
      api_key: sign_token
    }

    %Customer{}
    |> Customer.create_changeset(changeset)
    |> Repo.insert()
  end

  @spec update(customer_id :: id(), params :: params()) :: {:ok, customer()} | {:error, error()}
  def update(customer_id, changes) do
    Customer
    |> Repo.get(customer_id)
    |> Customer.changeset(changes)
    |> Repo.update()
  end

  @spec retrieve_by_id(customer_id :: id()) :: {:ok, customer() | nil}
  def retrieve_by_id(customer_id), do: {:ok, Repo.get(Customer, customer_id)}

  @spec verify_customer(token :: token()) :: {:ok, token_data()} | {:error, error()}
  def verify_customer(token) do
    {secret_key_base, signing_salt} = environment_secrets()

    Token.verify(secret_key_base, signing_salt, token)
  end

  @spec sign_token(data :: token_data(), age :: token_age()) :: token()
  defp sign_token(data, age \\ @token_age) do
    {secret_key_base, signing_salt} = environment_secrets()

    Token.sign(secret_key_base, signing_salt, data, max_age: age)
  end

  @spec generate_encrypted_token(customer_id :: id()) :: {token(), token()}
  defp generate_encrypted_token(customer_id) do
    sign_token = sign_token(%{customer_id: customer_id})
    {:ok, encrypted_token} = Cipher.encrypt_with_system_key(sign_token)

    {sign_token, encrypted_token}
  end

  @spec environment_secrets :: secrets()
  defp environment_secrets do
    {Application.get_env(:mintacoin, :secret_key_base),
     Application.get_env(:mintacoin, :signing_salt)}
  end
end

defmodule Mintacoin.Balances do
  @moduledoc """
  This module is responsible for doing operations for Balances
  """
  import Ecto.Query, only: [from: 2]

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Balance, Repo, Wallet}

  @type id :: UUID.t()
  @type changes :: map()
  @type error :: Changeset.t()
  @type balance :: Balance.t()
  @type balances :: Balance.t() | []
  @type amount :: Balance.balance()

  @spec create(changes :: changes()) :: {:ok, balance()} | {:error, error()}
  def create(changes) do
    %Balance{}
    |> Balance.create_changeset(changes)
    |> Repo.insert()
  end

  @spec update(id :: id(), changes :: changes()) :: {:ok, balance()} | {:error, error()}
  def update(id, changes) do
    Balance
    |> Repo.get(id)
    |> Balance.changeset(changes)
    |> Repo.update()
  end

  @spec update_by_wallet_id_and_asset_id(
          wallet_id :: id(),
          asset_id :: id(),
          changes :: changes()
        ) :: {:ok, balance()} | {:error, error()}
  def update_by_wallet_id_and_asset_id(wallet_id, asset_id, changes) do
    {:ok, balance} = retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)

    balance
    |> Balance.changeset(changes)
    |> Repo.update()
  end

  @spec increase_balance(id :: id(), amount :: amount()) :: {:ok, balance()} | {:error, error()}
  def increase_balance(id, amount) do
    %Balance{balance: balance_amount} = balance = Repo.get(Balance, id)

    new_balance =
      balance_amount
      |> Decimal.add(amount)
      |> Decimal.to_string(:normal)

    balance
    |> Balance.changeset(%{balance: new_balance})
    |> Repo.update()
  end

  @spec decrease_balance(id :: id(), amount :: amount()) :: {:ok, balance()} | {:error, error()}
  def decrease_balance(id, amount) do
    %Balance{balance: balance_amount} = balance = Repo.get(Balance, id)

    new_balance =
      balance_amount
      |> Decimal.sub(amount)
      |> Decimal.to_string(:normal)

    balance
    |> Balance.changeset(%{balance: new_balance})
    |> Repo.update()
  end

  @spec retrieve_by_wallet_id(wallet_id :: id()) :: {:ok, list(balances())}
  def retrieve_by_wallet_id(wallet_id) do
    query = from(blc in Balance, where: blc.wallet_id == ^wallet_id)
    {:ok, Repo.all(query)}
  end

  @spec retrieve_by_wallet_id_and_asset_id(wallet_id :: id(), asset_id :: id()) ::
          {:ok, balance() | nil}
  def retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id),
    do: {:ok, Repo.get_by(Balance, wallet_id: wallet_id, asset_id: asset_id)}

  @spec retrieve_by_account_id_and_blockchain_id(account_id :: id(), blockchain_id :: id()) ::
          {:ok, balances()}
  def retrieve_by_account_id_and_blockchain_id(account_id, blockchain_id) do
    query =
      from(blc in Balance,
        join: w in Wallet,
        on: w.id == blc.wallet_id,
        where: w.account_id == ^account_id and w.blockchain_id == ^blockchain_id
      )

    {:ok, Repo.all(query)}
  end
end

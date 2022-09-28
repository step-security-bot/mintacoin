defmodule Mintacoin.Assets do
  @moduledoc """
  This module is the responsible for the CRUD operations for assets and also for the aggregate operations within the assets context.
  """
  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Asset, Repo}

  @type id :: UUID.t()
  @type changes :: map()
  @type error :: Changeset.t()
  @type asset :: Asset.t() | nil

  @spec create(changes :: changes()) :: {:ok, asset()} | {:error, error()}
  def create(changes) do
    %Asset{}
    |> Asset.create_changeset(changes)
    |> Repo.insert()
  end

  @spec update(id :: id(), changes :: changes()) :: {:ok, asset()} | {:error, error()}
  def update(id, changes) do
    Asset
    |> Repo.get(id)
    |> Asset.changeset(changes)
    |> Repo.update()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, asset()}
  def retrieve_by_id(id), do: {:ok, Repo.get(Asset, id)}
end

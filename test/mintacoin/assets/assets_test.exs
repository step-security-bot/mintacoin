defmodule Mintacoin.Assets.AssetsTest do
  @moduledoc """
  This module is used to group common tests for Assets functions
  """

  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 1]

  alias Ecto.{Adapters.SQL.Sandbox, Changeset}
  alias Mintacoin.{Asset, Assets}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    asset = insert(:asset)

    %{
      asset: asset,
      code: "MTK",
      supply: 1000,
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create/1" do
    test "with valid params", %{code: code, supply: supply} do
      {:ok, %Asset{code: ^code, supply: ^supply}} = Assets.create(%{code: code, supply: supply})
    end

    test "with invalid code", %{supply: supply} do
      {:error,
       %Changeset{
         errors: [
           {:code, {"code must be alphanumeric", _detail}}
           | _tail
         ]
       }} = Assets.create(%{code: "M&L", supply: supply})
    end

    test "with invalid supply", %{code: code} do
      {:error,
       %Changeset{
         errors: [
           {:supply, {"must be greater than %{number}", _detail}}
           | _tail
         ]
       }} = Assets.create(%{code: code, supply: -1})
    end

    test "when missing params" do
      {:error,
       %Changeset{
         errors: [
           code: {"can't be blank", _},
           supply: {"can't be blank", _}
         ]
       }} = Assets.create(%{})
    end
  end

  describe "update/2" do
    test "with valid supply", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id, supply: 100}} = Assets.update(id, %{supply: 100})
    end

    test "with invalid supply", %{asset: %{id: id}} do
      {:error,
       %Changeset{
         errors: [
           {:supply, {"must be greater than %{number}", _detail}}
           | _tail
         ]
       }} = Assets.update(id, %{supply: -100})
    end
  end

  describe "retrieve_by_id/1" do
    test "when id exist", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id}} = Assets.retrieve_by_id(id)
    end

    test "when id doesn't exist", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = Assets.retrieve_by_id(not_existing_uuid)
    end
  end
end

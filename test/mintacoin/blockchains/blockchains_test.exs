defmodule Mintacoin.Blockchains.BlockchainsTest do
  @moduledoc """
    This module is used to group common tests for Blockchain functions
  """
  use Mintacoin.DataCase, async: false

  import Mintacoin.Factory, only: [insert: 2]

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset
  alias Mintacoin.{Blockchain, Blockchains}

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    %{
      name: "stellar",
      network: :testnet
    }
  end

  describe "create/2" do
    test "with a valid params", %{name: name, network: network} do
      {:ok, %Blockchain{name: ^name, network: ^network}} =
        Blockchains.create(%{name: name, network: network})
    end

    test "with invalid name", %{network: network} do
      {:error,
       %Changeset{
         errors: [
           {:name, {"is invalid", _detail}}
           | _tail
         ]
       }} = Blockchains.create(%{name: :testchain, network: network})
    end

    test "with invalid network", %{name: name} do
      {:error,
       %Changeset{
         errors: [
           {:network, {"is invalid", _detail}}
           | _tail
         ]
       }} = Blockchains.create(%{name: name, network: "testchain"})
    end

    test "when blockchain already exist", %{name: name, network: network} do
      insert(:blockchain, %{name: name, network: network})

      {:error,
       %Changeset{
         errors: [
           {_name, {"has already been taken", [{:constraint, :unique} | _constraint_name]}}
           | _tail
         ]
       }} = Blockchains.create(%{name: name, network: network})
    end
  end

  describe "retrieve/2" do
    test "when a blockchain exist", %{name: name, network: network} do
      %Blockchain{id: id} = insert(:blockchain, %{name: name, network: network})

      {:ok, %Blockchain{id: ^id}} = Blockchains.retrieve(name, network)
    end

    test "when a blockchain doesn't exist", %{name: name, network: network} do
      {:ok, nil} = Blockchains.retrieve(name, network)
    end

    test "with invalid name", %{network: network} do
      {:ok, nil} = Blockchains.retrieve("testchain", network)
    end
  end

  describe "retrieve/1" do
    test "when a blockchain exist", %{name: name} do
      %Blockchain{id: id} = insert(:blockchain, %{name: name, network: :mainnet})

      {:ok, %Blockchain{id: ^id, network: :mainnet}} = Blockchains.retrieve(name)
    end
  end
end

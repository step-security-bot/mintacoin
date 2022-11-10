defmodule MintacoinWeb.HomeControllerTest do
  @moduledoc """
  This module is used to test the home controller renderization
  """

  use MintacoinWeb.ConnCase

  describe "GET /v1-alpha" do
    test "with normal behaviour", %{conn: conn} do
      html =
        conn
        |> get("/v1-alpha")
        |> html_response(200)

      assert html =~ "Welcome to Mintacoin"
      assert html =~ "Minimalist API to run your crypto"
    end
  end

  describe "GET /" do
    test "with normal behaviour", %{conn: conn} do
      html =
        conn
        |> get("/")
        |> html_response(200)

      assert html =~ "Welcome to Mintacoin"
      assert html =~ "Minimalist API to run your crypto"
    end
  end
end

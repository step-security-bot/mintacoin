defmodule MintacoinWeb.HomeController do
  use MintacoinWeb, :controller

  def index(conn, _params) do
    home_redirect = Application.get_env(:mintacoin, :home_redirect_url)

    redirect(conn, external: home_redirect)
  end
end

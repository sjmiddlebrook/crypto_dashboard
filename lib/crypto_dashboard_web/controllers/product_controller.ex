defmodule CryptoDashboardWeb.ProductController do
  use CryptoDashboardWeb, :controller

  def index(conn, _params) do
    trades =
      CryptoDashboard.available_products()
      |> CryptoDashboard.get_last_trades()

    render(conn, "index.html", trades: trades)
  end
end

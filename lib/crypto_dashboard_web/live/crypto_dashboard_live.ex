defmodule CryptoDashboardWeb.CryptoDashboardLive do
  use CryptoDashboardWeb, :live_view

  def mount(_params, _session, socket) do
    products = CryptoDashboard.available_products()

    trades =
      products
      |> CryptoDashboard.get_last_trades()
      |> Enum.reject(&is_nil(&1))
      |> Enum.map(&{&1.product, &1})
      |> Enum.into(%{})

    if connected?(socket) do
      Enum.each(
        products,
        &CryptoDashboard.subscribe_to_trades(&1)
      )
    end

    socket = assign(socket, trades: trades, products: products)
    {:ok, socket}
  end

  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, fn trades -> Map.put(trades, trade.product, trade) end)
    {:noreply, socket}
  end
end

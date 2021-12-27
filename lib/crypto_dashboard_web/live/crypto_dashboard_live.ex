defmodule CryptoDashboardWeb.CryptoDashboardLive do
  use CryptoDashboardWeb, :live_view
  alias CryptoDashboard.Product
  import CryptoDashboardWeb.ProductHelpers

  def mount(_params, _session, socket) do
    socket = assign(socket, trades: %{}, products: [])
    {:ok, socket}
  end

  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, fn trades -> Map.put(trades, trade.product, trade) end)
    {:noreply, socket}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange_name, currency_pair)
    socket = add_product(socket, product)
    {:noreply, socket}
  end

  def handle_event("add-product", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("filter-products", %{"search" => search}, socket) do
    products =
      CryptoDashboard.available_products()
      |> Enum.filter(fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
          String.downcase(product.currency_pair) =~ String.downcase(search)
      end)
      {:noreply, assign(socket, :products, products)}
  end

  def add_product(socket, product) do
    add_product(product not in socket.assigns.products, socket, product)
  end

  defp add_product(true, socket, product) do
    CryptoDashboard.subscribe_to_trades(product)

    socket
    |> update(:products, fn products -> products ++ [product] end)
    |> update(:trades, fn trades ->
      trade = CryptoDashboard.get_last_trade(product)
      Map.put(trades, product, trade)
    end)
    |> put_flash(:info, "#{product.exchange_name} - #{product.currency_pair} added successfully")
  end

  defp add_product(_, socket, _product) do
    socket
    |> put_flash(:error, "product already added")
  end

  defp grouped_products_by_exchange_name() do
    CryptoDashboard.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end
end

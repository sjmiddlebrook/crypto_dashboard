defmodule CryptoDashboardWeb.CryptoDashboardLive do
  use CryptoDashboardWeb, :live_view
  alias CryptoDashboard.Product
  import CryptoDashboardWeb.ProductHelpers

  def mount(_params, _session, socket) do
    IO.inspect(self(), label: "LIVEVIEW MOUNT")
    socket = assign(socket, products: [])
    {:ok, socket}
  end

  def handle_info({:new_trade, trade}, socket) do
    send_update(CryptoDashboardWeb.ProductComponent, id: trade.product, trade: trade)
    {:noreply, socket}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    product = product_from_string(product_id)
    socket = add_product(socket, product)
    {:noreply, socket}
  end

  def handle_event("add-product", _params, socket) do
    {:noreply, socket}
  end


  def handle_event("remove-product", %{"product_id" => product_id} = _params, socket) do
    product = product_from_string(product_id)
    socket = update(socket, :products, &List.delete(&1, product))
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

  def product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  def add_product(socket, product) do
    add_product(product not in socket.assigns.products, socket, product)
  end

  defp add_product(true, socket, product) do
    CryptoDashboard.subscribe_to_trades(product)

    socket
    |> update(:products, fn products -> products ++ [product] end)
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

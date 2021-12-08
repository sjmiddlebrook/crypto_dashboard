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

  def render(assigns) do
    ~L"""
    <div class="flex flex-col">
      <div class="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
          <div class="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Traded at
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Exchange
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Currency
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Price
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Volume
                  </th>
                </tr>
              </thead>
              <tbody>
                <%= for product <- @products, trade = @trades[product], not is_nil(trade) do %>
                  <tr class="bg-white">
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <%= trade.traded_at %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <%= trade.product.exchange_name %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      <%= trade.product.currency_pair %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <%= trade.price %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <%= trade.volume %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, fn trades -> Map.put(trades, trade.product, trade) end)
    {:noreply, socket}
  end
end

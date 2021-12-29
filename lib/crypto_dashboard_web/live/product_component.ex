defmodule CryptoDashboardWeb.ProductComponent do
  use CryptoDashboardWeb, :live_component
  import CryptoDashboardWeb.ProductHelpers

  # def mount(socket) do
  #   IO.inspect(self(), label: "MOUNT")
  #   {:ok, socket}
  # end

  def update(%{trade: trade} = _assigns, socket) when not is_nil(trade) do
    socket = assign(socket, :trade, trade)
    {:ok, socket}
  end

  def update(assigns, socket) do
    product = assigns.id

    socket =
      socket
      |> assign(:product, product)
      |> assign(:trade, CryptoDashboard.get_last_trade(product))

    {:ok, socket}
  end
end

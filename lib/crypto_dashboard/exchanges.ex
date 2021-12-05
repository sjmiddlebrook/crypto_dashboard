defmodule CryptoDashboard.Exchanges do
  alias CryptoDashboard.{Product, Trade}

  @spec subscribe(Product.t()) :: :ok | {:error, term()}
  def subscribe(product) do
    Phoenix.PubSub.subscribe(CryptoDashboard.PubSub, topic(product))
  end

  @spec unsubscribe(Product.t()) :: :ok | {:error, term()}
  def unsubscribe(product) do
    Phoenix.PubSub.unsubscribe(CryptoDashboard.PubSub, topic(product))
  end

  @spec broadcast(Trade.t()) :: :ok | {:error, term()}
  def broadcast(trade) do
    Phoenix.PubSub.broadcast(CryptoDashboard.PubSub, topic(trade.product), {:new_trade, trade})
  end

  @spec topic(Product.t()) :: String.t()
  def topic(product) do
    to_string(product)
  end
end

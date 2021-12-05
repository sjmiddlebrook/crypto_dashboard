defmodule CryptoDashboard do
  defdelegate subscribe_to_trades(product), to: CryptoDashboard.Exchanges, as: :subscribe
  defdelegate unsubscribe_from_trades(product), to: CryptoDashboard.Exchanges, as: :unsubscribe

  defdelegate get_last_trade(product), to: CryptoDashboard.Historical
  defdelegate get_last_trades(products), to: CryptoDashboard.Historical
end

defmodule CryptoDashboard do
  defdelegate subscribe_to_trades(product), to: CryptoDashboard.Exchanges, as: :subscribe
  defdelegate unsubscribe_from_trades(product), to: CryptoDashboard.Exchanges, as: :unsubscribe
end

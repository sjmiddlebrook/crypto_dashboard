defmodule CryptoDashboard.Exchanges.CoinbaseClient do
  alias CryptoDashboard.{Trade, Product}
  alias CryptoDashboard.Exchanges.Client
  import Client, only: [validate_required: 2]

  @behaviour Client

  def exchange_name, do: "coinbase"
  def server_host, do: 'ws-feed.pro.coinbase.com'
  def server_port, do: 443

  def subscription_frames(currency_pairs) do
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    _trade =
      message_to_trade(msg)
      |> IO.inspect(label: "ticker")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t() | {:error, any()}}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ["product_id", "time", "price", "last_size"]),
         {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"]) do
      currency_pair = msg["product_id"]

      Trade.new(
        product: Product.new(exchange_name(), currency_pair),
        price: msg["price"],
        volume: msg["last_size"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end
end

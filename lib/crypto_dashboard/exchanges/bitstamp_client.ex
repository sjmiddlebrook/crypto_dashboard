defmodule CryptoDashboard.Exchanges.BitstampClient do
  alias CryptoDashboard.{Trade, Product}
  alias CryptoDashboard.Exchanges.Client
  import Client, only: [validate_required: 2]

  @behaviour Client

  def exchange_name, do: "bitstamp"
  def server_host, do: 'ws.bitstamp.net'
  def server_port, do: 443

  def handle_ws_message(%{"event" => "trade"} = msg, state) do
    _trade =
      message_to_trade(msg)
      |> IO.inspect(label: "ticker")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  def subscription_frames(currency_pairs) do
    Enum.map(currency_pairs, &subscription_frame(&1))
  end

  def subscription_frame(currency_pair) do
    msg =
      %{
        "event" => "bts:subscribe",
        "data" => %{
          "channel" => "live_trades_#{currency_pair}"
        }
      }
      |> Jason.encode!()

    {:text, msg}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t() | {:error, any()}}
  def message_to_trade(%{"data" => data, "channel" => "live_trades_" <> currency_pair})
      when is_map(data) do
    with :ok <- validate_required(data, ["timestamp", "price_str", "amount_str"]),
         {:ok, traded_at} <- convert_timestamp(data["timestamp"]) do
      Trade.new(
        product: Product.new(exchange_name(), currency_pair),
        price: data["price_str"],
        volume: data["amount_str"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end

  defp convert_timestamp(timestamp) do
    Integer.parse(timestamp)
    |> timestamp_to_datetime()
  end

  defp timestamp_to_datetime({value, _}), do: DateTime.from_unix(value)
  defp timestamp_to_datetime(_), do: {:error, :invalid_timestamp_string}
end

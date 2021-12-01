defmodule CryptoDashboard.Exchanges.BitstampClient do
  use GenServer
  alias CryptoDashboard.{Trade, Product}
  @exchange_name "bitstamp"

  def start_link(currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, currency_pairs, options)
  end

  def init(currency_pairs) do
    state = %{
      currency_pairs: currency_pairs,
      conn: nil,
    }
    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    updated_state = connect(state)
    {:noreply, updated_state}
  end

  def server_host, do: 'ws.bitstamp.net'
  def server_post, do: 443

  def connect(state) do
    {:ok, conn} = :gun.open(server_host(), server_post(), %{protocols: [:http]})
    %{state | conn: conn}
  end

  def handle_info({:gun_up, conn, :http}, %{conn: conn} = state) do
    :gun.ws_upgrade(state.conn, "/")
    {:noreply, state}
  end

  def handle_info({:gun_upgrade, conn, _ref, ["websocket"], _headers}, %{conn: conn} = state) do
    subscribe(state)
    {:noreply, state}
  end

  def handle_info({:gun_ws, conn, _ref, {:text, msg} = _frame}, %{conn: conn} = state) do
    handle_ws_message(Jason.decode!(msg), state)
  end

  def handle_ws_message(%{"event" => "trade"} = msg, state) do
    trade =
      message_to_trade(msg)
      |> IO.inspect(label: "ticker")
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  defp subscribe(state) do
    subscription_frames(state.currency_pairs)
    |> Enum.each(&:gun.ws_send(state.conn, &1))
  end

  def subscription_frames(currency_pairs) do
    Enum.map(currency_pairs, &subscription_frame(&1))
  end

  def subscription_frame(currency_pair) do
    msg = %{
            "event" => "bts:subscribe",
            "data" => %{
              "channel" => "live_trades_#{currency_pair}"
            },
          }
          |> Jason.encode!()
    {:text, msg}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t() | {:error, any()}}
  def message_to_trade(%{"data" => data, "channel" => "live_trades_" <> currency_pair}) when is_map(data) do
    with :ok <- validate_required(data, ["timestamp", "price_str", "amount_str"]),
         {:ok, traded_at} <- convert_timestamp(data["timestamp"])
      do
      Trade.new(
        product: Product.new(@exchange_name, currency_pair),
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


  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    Enum.find(keys, fn k -> is_nil(msg[k]) end)
    |> check_required_key()
  end

  defp check_required_key(nil), do: :ok
  defp check_required_key(required_key), do: {:error, {required_key, :required}}
end
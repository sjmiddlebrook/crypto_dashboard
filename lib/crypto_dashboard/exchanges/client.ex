defmodule CryptoDashboard.Exchanges.Client do
  use GenServer

  @type t :: %__MODULE__{
          module: module(),
          conn: pid(),
          conn_ref: reference(),
          currency_pairs: [String.t()]
        }

  @callback exchange_name() :: String.t()
  @callback server_host() :: list()
  @callback server_port() :: integer()
  @callback subscription_frames([String.t()]) :: [{:text, String.t()}]
  @callback handle_ws_message(map(), any()) :: any()

  defstruct [:module, :conn, :conn_ref, :currency_pairs]

  def start_link(module, currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, {module, currency_pairs}, options)
  end

  def init({module, currency_pairs}) do
    client = %__MODULE__{
      module: module,
      currency_pairs: currency_pairs
    }

    {:ok, client, {:continue, :connect}}
  end

  def handle_continue(:connect, client) do
    updated_state = connect(client)
    {:noreply, updated_state}
  end

  def connect(client) do
    host = server_host(client.module)
    port = server_port(client.module)
    {:ok, conn} = :gun.open(host, port, %{protocols: [:http]})
    conn_ref = Process.monitor(conn)
    %{client | conn: conn}
  end

  defp server_host(module), do: module.server_host()
  defp server_port(module), do: module.server_port()

  defp subscribe(client) do
    subscription_frames(client.module, client.currency_pairs)
    |> Enum.each(&:gun.ws_send(client.conn, &1))
  end

  defp subscription_frames(module, currency_pairs) do
    module.subscription_frames(currency_pairs)
  end

  def handle_info({:gun_up, conn, :http}, %{conn: conn} = client) do
    :gun.ws_upgrade(client.conn, "/")
    {:noreply, client}
  end

  def handle_info({:gun_upgrade, conn, _ref, ["websocket"], _headers}, %{conn: conn} = client) do
    subscribe(client)
    {:noreply, client}
  end

  def handle_info({:gun_ws, conn, _ref, {:text, msg} = _frame}, %{conn: conn} = client) do
    handle_ws_message(Jason.decode!(msg), client)
  end

  def handle_ws_message(msg, client) do
    module = client.module
    module.handle_ws_message(msg, client)
  end

  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    Enum.find(keys, fn k -> is_nil(msg[k]) end)
    |> check_required_key()
  end

  defp check_required_key(nil), do: :ok
  defp check_required_key(required_key), do: {:error, {required_key, :required}}
end

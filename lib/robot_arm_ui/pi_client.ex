defmodule RobotArmUi.PiClient do
  use WebSockex
  require Logger

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{}, name: __MODULE__)
  end

  def send_frame(frame) when is_binary(payload) do
    WebSockex.send_frame(__MODULE__, {:text, payload})
  end

  def handle_frame(_conn, state) do
    Logger.info("PiCLient: Connected to Raspberry.")
    {:ok, state}
  end

  def handle_disconnect(_conn, state) do
    Logger.info("PiClient: Disconnected from Raspberry. Reason: #{inspect(conn_status.reason)}")
    {:ok, state}
  end
end

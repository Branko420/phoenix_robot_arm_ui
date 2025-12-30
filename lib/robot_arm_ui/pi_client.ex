defmodule RobotArmUi.PiClient do
  use WebSockex
  require Logger

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{url: url})
  end

  def send_frame(payload) when is_binary(payload) do
    WebSockex.send_frame(__MODULE__, {:text, payload})
  end

  def handle_frame(_conn, state) do
    Logger.info("PiClient: Connected to Raspberry.")
    {:ok, state}
  end

  def send_command(pid, payload) do
    WebSockex.send_frame(pid, {:text, Jason.encode!(payload)})
  end

  def handle_disconnect(conn, state) do
    Logger.info("PiClient: Disconnected from Raspberry. Reason: #{inspect(conn.reason)}")
    {:ok, state}
  end
end

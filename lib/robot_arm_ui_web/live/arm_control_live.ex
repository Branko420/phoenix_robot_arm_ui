defmodule RobotArmUiWeb.ArmControlLive do
alias RobotArmUi.SequencePlayer
  use RobotArmUiWeb, :live_view
  alias RobotArmUi.PiClient
  alias RobotArmUi.Control

  def mount(_params, _session, socket) do
    {:ok,
      assign(socket,
      ip_input: "",
      connected_ip: nil,
      arm_pid: nil,
      is_admin: false,

      joints: %{"base"=> 90, "shoulder"=>90, "elbow"=>90, "wrist"=>90, "wrist_rotation"=>90, "gripper"=>90},
      duration: 1500,
      show_save_modal: false,
      sequences: RobotArmUi.Control.list_sequences()
      )}
  end

  def handle_event("update_ip_input", params, socket) do
    ip = params["ip"] || params["value"] || ""
    if String.downcase(ip) == "admin" do
      {:noreply, assign(socket, is_admin: true, connected_ip: "Admin Session", ip_input: "")}
    else
      {:noreply, assign(socket, ip_input: ip)}
    end
  end

  def handle_event("connect_to_arm", _params, socket) do
    url = "ws://#{socket.assigns.ip_input}:8765"
    case PiClient.start_link(url) do
      {:ok, pid} ->
        {:noreply, assign(socket, arm_pid: pid, connected_ip: socket.assigns.ip_input)}
      _error ->
        {:noreply, put_flash(socket, :error, "Connection failed.")}
    end
  end

  def handle_event("reset_session", _params, socket) do
    if socket.assigns.arm_pid, do: GenServer.stop(socket.assigns.arm_pid)
    {:noreply, assign(socket, connected_ip: nil, is_admin: false, arm_pid: nil, ip_input: "")}
  end

  def handle_event("move", %{"joint" => joint, "value" => value}, socket) do
    angle = String.to_float(value)
    new_joints = Map.put(socket.assigns.joints, joint, angle)

    if socket.assigns.arm_pid do
      payload = %{"duration" => socket.assigns.duration / 1000.0, "joints" => %{joint => angle}}
      PiClient.send_frame(socket.assigns.arm_pid, Jason.encode!(payload))
    end
    {:noreply, assign(socket, joints: new_joints)}
  end

  def handle_event("update_duration", %{"value" => value}, socket) do
    {:noreply, assign(socket, duration: String.to_integer(value))}
  end

  def handle_event("open_save_modal", _params, socket) do
    {:noreply, assign(socket, show_save_modal: true)}
  end

  def handle_event("close_save_modal", _params, socket) do
    {:noreply, assign(socket, show_save_modal: false)}
  end

  def handle_event("confirm_save", %{"name" => name}, socket) do
    case Control.create_sequence(name) do
      {:ok, _sequence} ->
        {:noreply,
          socket
          |> assign(show_save_modal: false, sequences: Control.list_sequences())
          |> put_flash(:info, "Sequence saved.")
        }
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Save Failed.")}
    end
  end

  def handle_event("delete_sequance", %{"id" => id}, socket) do
    Control.delete_sequence(id)
    {:noreply, assign(socket, sequences: Control.list_sequences())}
  end

  def handle_event("load_sequence", %{"id" => id}, socket) do
    Task.start(fn ->
      SequencePlayer. play_sequence(String.to_integer(id), socket.assigns.arm_pid)
    end)
    {:noreply, socket}
  end
end

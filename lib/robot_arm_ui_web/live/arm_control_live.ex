defmodule RobotArmUiWeb.ArmControlLive do
alias RobotArmUi.SequencePlayer
  use RobotArmUiWeb, :live_view
  alias RobotArmUi.PiClient
  alias RobotArmUi.Control

  def mount(_params, _session, socket) do
    sequences = Control.list_sequences() || []
    {:ok,
      assign(socket,
      ip_input: "",
      connected_ip: nil,
      arm_pid: nil,
      is_admin: false,
      editing_id: nil,

      joints: %{"base"=> 90, "shoulder"=>90, "elbow"=>90, "wrist"=>90, "wrist_rotation"=>90, "gripper"=>90},
      duration: 1500,
      show_save_modal: false,
      sequences: sequences
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

  def handle_event("connect_to_arm", %{"ip" => ip}, socket) do
    if String.downcase(ip) == "admin" do
      {:noreply,
        socket
        |> assign(is_admin: true, connected_ip: "Admin Session", ip_input: "")
        |> put_flash(:info, "Granted")
      }
    else
      url = "ws://#{ip}:8765"
      case PiClient.start_link(url) do
        {:ok, pid} ->
          {:noreply,
        socket
        |> assign(arm_pid: pid, connected_ip: ip, ip_input: ip)
        |> put_flash(:info, "Connected to Robot Arm at #{ip}")}
          _error ->
            {:noreply,
          socket
          |> put_flash(:error, "Failed to connect to Robot Arm at #{ip}")
      }
      end
    end
  end

  def handle_event("reset_session", _params, socket) do
    if socket.assigns.arm_pid, do: GenServer.stop(socket.assigns.arm_pid)
    {:noreply, assign(socket, connected_ip: nil, is_admin: false, arm_pid: nil, ip_input: "")}
  end

  def handle_event("move", %{"joint" => joint, "value" => value}, socket) do
    parsed_num =
    case Float.parse(to_string(value)) do
      {num, _} -> num
      :error -> socket.assigns.joints[joint]
    end

  # 2. APPLY THE CLAMP (This was missing)
  safe_val = clamp_joint(joint, parsed_num)

  # 3. Update State
  new_joints = Map.put(socket.assigns.joints, joint, safe_val)
  socket = clear_flash(socket)

  {:noreply, assign(socket, joints: new_joints)}
  end

  def handle_event("execute_move", _params, socket) do
    if socket.assigns.arm_pid do
      payload = %{"duration" => socket.assigns.duration / 1000.0, "joints" => socket.assigns.joints}
      PiClient.send_frame(socket.assigns.arm_pid, Jason.encode!(payload))
      {:noreply, put_flash(socket, :info, "Movement Executed")}
    else
      {:noreply, put_flash(socket, :error, "Not connected to Robot Arm")}
    end

  end

  def handle_event("update_duration", %{"value" => value}, socket) do
    safe_duration = case Integer.parse(value) do
      {num, _} ->
        max(num, 1000)

      :error ->
        socket.assigns.duration
    end

    {:noreply, assign(socket, duration: safe_duration)}
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

  def handle_event("delete_sequence", %{"id" => id} = _params, socket) do
    Control.delete_sequence(id)

    new_socket =
      socket
      |> assign(sequences: Control.list_sequences())
      |> put_flash(:info, "Sequence deleted.")
    {:noreply, new_socket}
  end

  def handle_event("load_sequence", %{"id" => id}, socket) do
    Task.start(fn ->
      SequencePlayer. play_sequence(String.to_integer(id), socket.assigns.arm_pid)
    end)
    {:noreply, socket}
  end

  def handle_event("move_on_enter", %{"key" => "Enter", "joint" => joint, "value" => value}, socket) do
    handle_event("move", %{"joint" => joint, "value" => value}, socket)
  end

  def handle_event("move_on_enter", _params, socket) do
    {:noreply, socket}
  end

  defp clamp_joint("gripper", angle), do: min(max(angle, 70.0), 130.0)
  defp clamp_joint("wrist_rotation", angle), do: min(max(angle, 10.0), 170.0)
  defp clamp_joint("wrist", angle), do: min(max(angle, 0.0), 180.0)
  defp clamp_joint("elbow", angle), do: min(max(angle, 10.0), 170.0)
  defp clamp_joint("shoulder", angle), do: min(max(angle, 20.0), 160.0)
  defp clamp_joint("base", angle), do: min(max(angle, 0.0), 180.0)
  defp clamp_joint(_, angle), do: angle
  defp get_limits(joint) do
  case joint do
    "gripper" -> {70.0, 130.0}
    "wrist_rotation" -> {10.0, 170.0}
    "elbow" -> {10.0, 170.0}
    "shoulder" -> {20.0, 160.0}
    "wrist" -> {0.0, 180.0}
    "base" -> {0.0, 180.0}
    _ -> {0.0, 180.0}
  end
end
end

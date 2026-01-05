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
    Process.send_after(self(), :clear_flash, 5000)
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

  def handle_event("ignore_enter", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("move", params, socket) do
    joint = params["joint"]
    target = params["_target"] || []

    raw_value =
      cond do
        "slider_input" in target -> params["slider_input"]
        "number_input" in target -> params["number_input"]
        true                     -> params["slider_input"]
      end

    IO.inspect(raw_value, label: ">>> INPUT RECEIVED")

    parsed_num =
      case Float.parse(to_string(raw_value)) do
        {num, _} -> num
        :error -> socket.assigns.joints[joint]
      end

    safe_val = clamp_joint(joint, parsed_num)

    IO.inspect(safe_val, label: ">>> SAFETY CLAMPED TO")

    new_joints = Map.put(socket.assigns.joints, joint, safe_val)
    {:noreply, assign(socket, joints: new_joints)}
  end

  def handle_event("execute_move", _params, socket) do
    Process.send_after(self(), :clear_flash, 5000)
    if socket.assigns.arm_pid do
      # Convert Milliseconds (4500) -> Seconds (4.5)
      payload = %{
        "duration" => socket.assigns.duration / 1000.0,
        "joints" => socket.assigns.joints
      }

      PiClient.send_frame(socket.assigns.arm_pid, Jason.encode!(payload))
      {:noreply, put_flash(socket, :info, "Movement Executed")}
    else
      {:noreply, put_flash(socket, :error, "Not connected to Robot Arm")}
    end
  end

  def handle_event("update_duration", params, socket) do
    IO.inspect(params, label: ">>> DURATION EVENT")

    raw_val = params["value"]

    safe_duration = case Integer.parse(to_string(raw_val)) do
      {num, _} -> max(num, 1000)
      :error ->
        IO.puts(">>> ERROR PARSING DURATION")
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
    current_joints = socket.assigns.joints
    duration_ms = socket.assigns.duration

    movement_attrs = %{
      "joint1" => current_joints["gripper"],
      "joint2" => current_joints["wrist_rotation"],
      "joint3" => current_joints["wrist"],
      "joint4" => current_joints["elbow"],
      "joint5" => current_joints["shoulder"],
      "joint6" => current_joints["base"],
      "delay_ms" => duration_ms
    }

    sequence_attrs = %{"name" => name, "movements" => [movement_attrs]}

    case Control.create_sequence(sequence_attrs) do
      {:ok, _sequence} ->

        Process.send_after(self(), :clear_flash, 5000)
        {:noreply,
          socket
          |> assign(show_save_modal: false)
          |> assign(sequences: Control.list_sequences())
          |> put_flash(:info, "Pose saved successfully.")
        }
        {:error, _changeset} ->
          Process.send_after(self(), :clear_flash, 3000)
          {:noreply, put_flash(socket, :error, "Failed to save pose.")}
    end
  end

  def handle_event("delete_sequence", %{"id" => id} = _params, socket) do
    Control.delete_sequence(id)

    Process.send_after(self(), :clear_flash, 5000)

    {:noreply,
      socket
      |> assign(sequences: Control.list_sequences())
      |> put_flash(:info, "Pose deleted.")}
  end

  def handle_event("edit_sequence", %{"id" => id}, socket) do
    sequence = Control.get_sequence!(String.to_integer(id))

    movement = List.first(sequence.movements)

    Process.send_after(self(), :clear_flash, 5000)
    if movement do
      loaded_joints = %{
        "base"           => movement.joint6,
        "shoulder"       => movement.joint5,
        "elbow"          => movement.joint4,
        "wrist"          => movement.joint3,
        "wrist_rotation" => movement.joint2,
        "gripper"        => movement.joint1
      }

      {:noreply,
        socket
        |> assign(joints: loaded_joints)
        |> assign(duration: movement.delay_ms || 1500)
        |> assign(editing_id: sequence.id, editing_name: sequence.name)
        |> put_flash(:info, "Editing '#{sequence.name}'. Adjust sliders and click Update.")
      }
    else
      {:noreply, put_flash(socket, :error, "Pose has no movements.")}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    Process.send_after(self(), :clear_flash, 3000)
    {:noreply,
      socket
      |> assign(editing_id: nil)
      |> assign(editing_name: nil)
      |> put_flash(:info, "Edit cancelled.")
    }
  end

  def handle_event("confirm_update_sequence", _params, socket) do
    if socket.assigns.editing_id do
      original_sequence = Control.get_sequence!(socket.assigns.editing_id)

      current_joints = socket.assigns.joints
      duration_ms = socket.assigns.duration || 1500

      movement_attrs = %{
        "joint1" => current_joints["gripper"],
        "joint2" => current_joints["wrist_rotation"],
        "joint3" => current_joints["wrist"],
        "joint4" => current_joints["elbow"],
        "joint5" => current_joints["shoulder"],
        "joint6" => current_joints["base"],
        "delay_ms" => duration_ms
      }

      # We keep the original name, but update the movements
      attrs = %{
        "name" => socket.assigns.editing_name,
        "movements" => [movement_attrs]
      }
      Process.send_after(self(), :clear_flash, 3000)
      case Control.update_sequence(original_sequence, attrs) do
        {:ok, _updated} ->
          Process.send_after(self(), :clear_flash, 5000)
          {:noreply,
            socket
            |> assign(editing_id: nil) # Exit edit mode
            |> assign(editing_name: nil)
            |> assign(sequences: Control.list_sequences()) # Refresh list
            |> put_flash(:info, "Pose updated successfully.")
          }

        {:error, _} ->
          Process.send_after(self(), :clear_flash, 5000)
          {:noreply, put_flash(socket, :error, "Failed to update pose.")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_sequence", %{"id" => id}, socket) do
    seq_id = String.to_integer(id)
    pid = socket.assigns.arm_pid

    Process.send_after(self(), :clear_flash, 5000)
    if pid do
      # Run the sequence in a separate process so the UI doesn't freeze
      Task.start(fn ->
        SequencePlayer.play_sequence(seq_id, pid)
      end)

      {:noreply, put_flash(socket, :info, "Pose started...")}
    else
      {:noreply, put_flash(socket, :error, "Not connected to Robot Arm")}
    end
  end

  def handle_event("move_on_enter", %{"key" => "Enter", "joint" => joint, "value" => value}, socket) do
    handle_event("move", %{"joint" => joint, "value" => value}, socket)
  end

  def handle_event("move_on_enter", _params, socket) do
    {:noreply, socket}
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp clamp_joint("gripper", angle), do: min(max(angle, 70.0), 130.0)
  defp clamp_joint("wrist_rotation", angle), do: min(max(angle, 0.0), 180.0)
  defp clamp_joint("wrist", angle), do: min(max(angle, 10.0), 170.0)
  defp clamp_joint("elbow", angle), do: min(max(angle, 10.0), 170.0)
  defp clamp_joint("shoulder", angle), do: min(max(angle, 20.0), 160.0)
  defp clamp_joint("base", angle), do: min(max(angle, 0.0), 180.0)
  defp clamp_joint(_, angle), do: angle
end

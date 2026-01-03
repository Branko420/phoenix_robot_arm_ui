defmodule RobotArmUi.SequencePlayer do
  alias RobotArmUi.Repo
  alias RobotArmUi.PiClient
  import Ecto.Query

  def play_sequence(sequence_id, arm_pid) do
    sequence =
      RobotArmUi.Sequence
      |> Repo.get!(sequence_id)
      |> Repo.preload([movements: from(m in RobotArmUi.Movement, order_by: m.inserted_at)])

    Enum.each(sequence.movements, fn movement ->
      duration_sec = (movement.delay_ms || 1500) / 1000.0
      pose = %{
        "duration" => duration_sec,
        "joints" => %{
          "base" => movement.joint6,
          "shoulder" => movement.joint5,
          "elbow" => movement.joint4,
          "wrist" => movement.joint3,
          "wrist_rotation" => movement.joint2,
          "gripper" => movement.joint1
        }
      }
      if arm_pid, do: PiClient.send_frame(arm_pid, Jason.encode!(pose))

      delay = movement.delay_ms || 1500
      Process.sleep(delay)
    end)
  end
end

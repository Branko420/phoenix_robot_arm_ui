defmodule RobotArmUi.SequencePlayer do
  alias RobotArmUi.Repo
  alias RobotArmUi.PiClient
  import Ecto.Query

  def play_sequence(sequence_id) do
    movements =
      RobotArmUi.Movement
      |> where(sequence_id: ^sequence_id)
      |> order_by(:inserted_at)
      |> Repo.all()
    Enum.each(movements, fn movement ->
      pose = %{
        "duration" => movement.duration || 1.5,
        "joints" => %{
          "base" => movement.joint6,
          "shoulder" => movement.joint5,
          "elbow" => movement.joint4,
          "wrist" => movement.joint3,
          "wrist_rotation" => movement.joint2,
          "gripper" => movement.joint1
        }
      }
      PiClient.send_frame(Jason.encode!(pose))

      delay = movement.delay_ms || 2000
      Process.sleep(delay)
    end)
  end
end

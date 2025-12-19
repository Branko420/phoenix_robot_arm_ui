defmodule RobotArmUi.Repo do
  use Ecto.Repo,
    otp_app: :robot_arm_ui,
    adapter: Ecto.Adapters.Postgres
end

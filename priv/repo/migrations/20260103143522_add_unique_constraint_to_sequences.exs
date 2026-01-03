defmodule RobotArmUi.Repo.Migrations.AddUniqueConstraintToSequences do
  use Ecto.Migration

  def change do
    create unique_index(:sequences, [:name])
  end
end

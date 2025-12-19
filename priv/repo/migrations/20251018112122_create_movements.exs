defmodule RobotArmUi.Repo.Migrations.CreateMovements do
  use Ecto.Migration

  def change do
    create table(:movements) do
      add :joint1, :float
      add :joint2, :float
      add :joint3, :float
      add :joint4, :float
      add :joint5, :float
      add :joint6, :float
      add :delay_ms, :integer
      add :sequence_id, references(:sequences, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:movements, [:sequence_id])
  end
end

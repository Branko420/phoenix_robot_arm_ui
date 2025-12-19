defmodule RobotArmUi.Repo.Migrations.CreateSequences do
  use Ecto.Migration

  def change do
    create table(:sequences) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end

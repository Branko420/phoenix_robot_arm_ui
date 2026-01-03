defmodule RobotArmUi.Sequence do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sequences" do
    field :name, :string
    has_many :movements, RobotArmUi.Movement,on_replace: :delete, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sequence, attrs) do
    sequence
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> cast_assoc(:movements, with: &RobotArmUi.Movement.changeset/2)
  end
end

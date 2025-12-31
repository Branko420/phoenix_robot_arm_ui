defmodule RobotArmUi.Sequence do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sequences" do
    field :name, :string
    has_many :movements, RobotArmUi.Movement

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sequence, attrs) do
    sequence
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end

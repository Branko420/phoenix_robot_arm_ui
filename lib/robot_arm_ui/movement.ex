defmodule RobotArmUi.Movement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "movements" do
    field :joint1, :float
    field :joint2, :float
    field :joint3, :float
    field :joint4, :float
    field :joint5, :float
    field :joint6, :float
    field :delay_ms, :integer
    field :sequence_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(movement, attrs) do
    movement
    |> cast(attrs, [:joint1, :joint2, :joint3, :joint4, :joint5, :joint6, :delay_ms])
    |> validate_required([:joint1, :joint2, :joint3, :joint4, :joint5, :joint6, :delay_ms])
  end
end

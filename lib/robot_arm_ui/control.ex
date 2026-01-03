defmodule RobotArmUi.Control do
  import Ecto.Query, warn: false
  alias RobotArmUi.Repo
  alias RobotArmUi.Sequence

  def list_sequences do
    from(s in Sequence, order_by: [desc: s.inserted_at])
    |> Repo.all()
  end

  def create_sequence(attrs) do
    %Sequence{}
    |> Sequence.changeset(attrs)
    |> Repo.insert()
  end

  def get_sequence!(id) do
    Sequence
    |> Repo.get!(id)
    |> Repo.preload(:movements)
  end
  def delete_sequence(id) do
    id_int = if is_binary(id), do: String.to_integer(id), else: id
    sequence = Repo.get!(Sequence, id_int)
    Repo.delete(sequence)
  end

  def update_sequence(%Sequence{} = sequence, attrs) do
    sequence
    |> Sequence.changeset(attrs)
    |> Repo.update()
  end
end

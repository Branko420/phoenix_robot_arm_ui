defmodule RobotArmUi.Control do
  alias RobotArmUi.Repo
  alias RobotArmUi.Sequence

  def list_sequences, do: Repo.all(Sequence)

  def create_sequence(name) do
    %Sequence{}
    |> Sequence.changeset(%{name: name})
    |> Repo.insert()
  end

  def delete_sequence(id) do
    id_int = if is_binary(id), do: String.to_integer(id), else: id
    sequence = Repo.get!(Sequence, id_int)
    Repo.delete(sequence)
  end

end

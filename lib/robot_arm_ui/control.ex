defmodule RobotArmUi.Control do
  alias RobotArmUi.Repo
  alias RobotArmUi.Sequence

  def list_sequences, do: Repo.all(Sequence)

  def create_sequence(name) do
    %Sequence{}
    |> Sequence.changeset(%{name: name})
    |> Repo.insert()
  end

  def delete_sequence(%Sequence{} = sequence), do: Repo.delete(sequence)

end

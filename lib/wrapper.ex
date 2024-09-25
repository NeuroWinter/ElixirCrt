defmodule CrtWrapper do
  @moduledoc false

  use HTPoison.Base

  @spec process_body(String.t()) :: list
  defp process_body(body) do
    body
    |> Poison.decode!()
    |> Enum.reduce([], fn x, acc ->
      common_name = get_common_name(x)
      if common_name, do: [common_name | acc], else: acc
    end)
    # Make sure that we don't have duplicates.
    |> Enum.uniq()
  end

end

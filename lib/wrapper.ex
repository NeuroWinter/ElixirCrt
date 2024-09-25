defmodule CrtWrapper do
  @moduledoc false

  use HTTPoison.Base

  @spec process_body(String.t()) :: list
  def process_body(body) do
    body
    |> Poison.decode!()
    |> Enum.reduce([], fn x, acc ->
      common_name = get_common_name(x)
      if common_name, do: [common_name | acc], else: acc
    end)
    # Make sure that we don't have duplicates.
    |> Enum.uniq()
  end

  @spec get_common_name(map) :: String.t()
  defp get_common_name(domain_info) do
    common_name = Map.fetch!(domain_info, "common_name")
    # We want to make sure that we are removing any wildcard domains.
    if not String.contains?(common_name, "*") do
      common_name
    end
  end

end

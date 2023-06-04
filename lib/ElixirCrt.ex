defmodule ElixirCrt do
  @moduledoc """
  Documentation for `ElixirCrt`.
  """
  use HTTPoison.Base

  @spec get_headers() :: List
  defp get_headers do
    [
      {
        "user-agent",
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
      }
    ]
  end

  @spec get_valid_tlds() :: List
  defp get_valid_tlds() do
    {_status, contents} = File.read("lib/valid_tlds.txt")
    contents
    |> String.split("\n", trim: true)
  end

  @spec is_valid_domain?(String) :: Boolean
  defp is_valid_domain?(domain) do
    tld = domain
    |> String.split(".")
    # We need to see if the tld which should be the last item after spliting by
    # '.' is in the list of known tlds.
    |> List.last()
    Enum.member?(get_valid_tlds(), String.upcase(tld))  
    # TODO I want to add some more checks here to make sure there are no weird
    # characters in the domain. One way I can do that is either regex or the URI
    # dep.
  end


  @spec get_common_name(Map) :: String
  defp get_common_name(domain_info) do
    common_name = Map.fetch!(domain_info, "common_name")
    # We want to make sure that we are removing any wildcard domains.
    if not String.contains?(common_name, "*") do
      common_name
    end
  end

  @spec process_body(String) :: List
  defp process_body(body) do
    body
    |> Poison.decode!()
    |> Enum.reduce( [], fn x, acc -> [ get_common_name(x) | acc] end)
    # Make sure that we don't have duplicates.
    |> Enum.uniq()
    # Remove nils as the reduce function can add nils to the list.
    |> Enum.filter(& !is_nil(&1))
  end

  @doc """
  Get all of the subdomains that are on crt.sh  

  Note this can take some time as the upstream server can be slow at times.
  """
  @spec get_subdomains(String, Boolean) :: [String.t]
  def get_subdomains(domain, wildcard \\ true) do
    valid_domain = is_valid_domain?(domain)
    if not valid_domain do
      IO.puts("Please specify a valid domain.")
      {:error, "Invalid domain."}
    else
      response = 
      if wildcard do
        # To make sure that we get all of the domains we can use a wildcard
        # on crt,sh this is a '%.' in front of the domain.
        "https://crt.sh/?q=" <> "%." <> domain <> "&output=json" 
      else
        "https://crt.sh/?q=" <> domain <> "&output=json"
      end
      |> ElixirCrt.get!(get_headers(), [timeout: :infinity, recv_timeout: :infinity])
      # We should make sure that the request went though.
      IO.puts(response.status_code())
      if response.status_code() == 200 do
        process_body(response.body()) 
      else
        {:error, "There was an error connecting to https://crt.sh/ - Status Code: " <>  to_string(response.status_code())}
      end
    end
  end
end
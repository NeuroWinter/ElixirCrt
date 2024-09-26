defmodule ElixirCrt do
  @moduledoc """
  Documentation for `ElixirCrt`.
  """
  # Reading it as an attribute will prevent reading the file each time at run time.
  # @external_resource will trigger a recompile if the file is changed.
  @external_resource tld_file = File.read!("lib/valid_tlds.txt")

  @valid_tlds tld_file
              |> String.split("\n", trim: true)

  @spec valid_tlds() :: list
  defp valid_tlds() do
    @valid_tlds
  end

  @spec get_headers() :: List
  defp get_headers do
    [
      {
        "user-agent",
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0"
      }
    ]
  end


  @spec ensure_valid_domain(String.t()) :: :ok
  defp ensure_valid_domain(domain) do
    tld =
      domain
      |> String.split(".")
      |> List.last()
      |> String.upcase()

    with true <- tld in valid_tlds() do
      :ok
    else
      _ -> raise "Invalid Domain"
    end
  end

  @spec get_common_name(map) :: String.t()
  defp get_common_name(domain_info) do
    common_name = Map.fetch!(domain_info, "common_name")
    # We want to make sure that we are removing any wildcard domains.
    if not String.contains?(common_name, "*") do
      common_name
    end
  end


  @doc """
  Get all of the subdomains that are on crt.sh

  Note this can take some time as the upstream server can be slow at times.

  # Arguments
    - `domain` : String - The domain that you want to get the subdomains for. eg. "NeuroWinter.com"
    - `wildcard` : Boolean - If you want to include wildcard domains in the search. eg *.domain.com
    - `timeout` : Interger or :infinity  - The timeout for the request in milliseconds.

  ## Examples

      iex(2)> ElixirCrt.get_subdomains("NeuroWinter.com")
      {:ok, ["neurowinter.com", "sni.cloudflaressl.com", "mta-sts.neurowinter.com"]}

  """
  @spec get_subdomains(String, Boolean, Interger) :: [String.t]
  def get_subdomains(domain, wildcard \\ true, timeout \\ :infinity ) do
    ensure_valid_domain(domain)
    response = response_url(domain, wildcard)
    |> CrtWrapper.get!(get_headers(), [timeout: timeout, recv_timeout: timeout])
    # We should make sure that the request went though.
    if response.status_code == 200 do
      {:ok, CrtWrapper.process_body(response.body)}
    else
      {:error, "There was an error connecting to https://crt.sh/ - Status Code: " <>  to_string(response.status_code())}
    end
  end

  defp response_url(domain, wildcard) do
    wildcard = if wildcard, do: "%.", else: ""
    "https://crt.sh/?q=#{wildcard}#{domain}&output=json"
  end
end

defmodule ElixirCrt do
  @moduledoc """
  Documentation for `ElixirCrt`.
  """

  # This is effectively a infinite time out, this is needed as crt.sh can take
  # a long time to reply.
  Req.default_options(receive_timeout: 10_000_000_000)

  defp get_tlds() do
    %{status: 200, body: body} = Req.get!("https://data.iana.org/TLD/tlds-alpha-by-domain.txt")
    # Here we need to delete the first line of thy body as this contains a comment.
    String.split(body, "\n", trim: true)
    |> List.delete_at(0)
  end

  @spec valid_tlds() :: list
  defp valid_tlds() do
    get_tlds()
  end

  @doc """
  Get all of the subdomains that are on crt.sh  

  Note this can take some time as the upstream server can be slow at times.
  """
  @get_headers [
    "user-agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/113.0",
    "content-type": "application/json"
  ]

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

  @spec process_body(String.t()) :: list
  defp process_body(body) do
    body
    # Here we need to replace all the new lines that are present as they will
    # break Jason, as it follows the json spec strictly
    |> Poison.decode!()
    |> Enum.reduce([], fn x, acc ->
      common_name = get_common_name(x)
      if common_name, do: [common_name | acc], else: acc
    end)
    # Make sure that we don't have duplicates.
    |> Enum.uniq()
  end

  @doc """
  Get all of the subdomains that are on crt.sh  

  Note this can take some time as the upstream server can be slow at times.
  """
  @spec get_subdomains(String.t(), boolean) :: [String.t()]
  def get_subdomains(domain, wildcard \\ true) do
    ensure_valid_domain(domain)

    IO.puts(response_url(domain, wildcard))
    %{status: 200, body: body} = Req.get!(response_url(domain, wildcard), headers: @get_headers)
    {:ok, process_body(body)}
  end

  defp response_url(domain, wildcard) do
    wildcard = if wildcard, do: "%.", else: ""
    URI.encode("https://crt.sh/?q=#{wildcard}#{domain}&output=json")
  end
end

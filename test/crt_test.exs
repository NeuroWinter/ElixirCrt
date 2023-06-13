defmodule CrtTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "client can handle an error response", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/?q=%.test.com&output=json", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<[{"common_name": "foobar.test.com"},
                                    {"common_name": "bazbar.test.com"}]>)
    end)
    ["foobar.test.com", "bazbar.test.com"] = ElixirCrt.get_subdomains("test.com")
  end
end

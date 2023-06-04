defmodule CrtTest do
  use ExUnit.Case
  doctest Crt

  test "greets the world" do
    assert Crt.hello() == :world
  end
end

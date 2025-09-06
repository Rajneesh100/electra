defmodule ElectraTest do
  use ExUnit.Case
  doctest Electra

  test "greets the world" do
    assert Electra.hello() == :world
  end
end

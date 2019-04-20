defmodule LoggerGelfTest do
  use ExUnit.Case
  doctest LoggerGelf

  test "greets the world" do
    assert LoggerGelf.hello() == :world
  end
end

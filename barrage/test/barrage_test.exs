defmodule BarrageTest do
  use ExUnit.Case
  doctest Barrage

  describe "Barrage module" do
    test "hello/0 returns :world" do
      assert Barrage.hello() == :world
    end
  end
end

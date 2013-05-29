Code.require_file "test_helper.exs", __DIR__

defmodule JSXTest do
  use ExUnit.Case

  test "decode empty object" do
    assert(JSX.decode("{}") == [{}])
  end
  
  test "decode empty list" do
    assert(JSX.decode("[]") == [])
  end
  
  test "decode literals" do
    assert(JSX.decode("[true, false, null]") == [:true, :false, :nil])
  end
  
  test "decode numbers" do
    assert(
      JSX.decode("[-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617]")
        == [-18446744073709551617, -1.0, -1, 0, 0, 1, 1.0, 18446744073709551617]
      )
  end
  
  test "decode strings" do
    assert(JSX.decode("[\"hallo\", \"world\"]") == ["hallo", "world"])
  end
  
end

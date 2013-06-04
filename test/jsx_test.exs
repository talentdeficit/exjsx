Code.require_file "test_helper.exs", __DIR__

defmodule JSXTest do
  use ExUnit.Case

  test "decode empty object" do
    assert(JSX.decode!("{}") == [{}])
  end
  
  test "encode empty object" do
    assert(JSX.encode!([{}]) == "{}")
  end
  
  test "decode empty list" do
    assert(JSX.decode!("[]") == [])
  end

  test "encode empty list" do
    assert(JSX.encode!([]) == "[]")
  end
  
  test "encode list of empty lists" do
    assert(JSX.encode!([[], [], []]) == "[[],[],[]]")
  end
  
  test "encode list of empty objects" do
    assert(JSX.encode!([[{}], [{}], [{}]]) == "[{},{},{}]")
  end
  
  test "decode literals" do
    assert(JSX.decode!("[true, false, null]") == [:true, :false, :nil])
  end
  
  test "encode literals" do
    assert(JSX.encode!([:true, :false, :nil]) == "[true,false,null]")
  end
  
  test "decode numbers" do
    assert(
      JSX.decode!("[-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617]")
        == [-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617]
      )
  end
  
  test "encode numbers" do
    assert(
      JSX.encode!([-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617])
        == "[-18446744073709551617,-1.0,-1,0,0.0,1,1.0,18446744073709551617]"
      )
  end
  
  test "decode strings" do
    assert(JSX.decode!("[\"hallo\", \"world\"]") == ["hallo", "world"])
  end

  test "encode strings" do
    assert(JSX.encode!(["hallo", "world"]) == "[\"hallo\",\"world\"]")
  end
  
  test "decode simple object" do
    assert(JSX.decode!("{\"key\": true}") == [key: true])
  end
  
  test "encode simple object" do
    assert(JSX.encode!([key: true]) == "{\"key\":true}")
  end
  
  test "decode compound object" do
    assert(JSX.decode!(
      "{\"a\": [ true, false, null ], \"b\": \"hallo world\", \"c\": {
        \"x\": [ 1,2,3 ], \"y\": {}, \"z\": [[[]]]
      }}") == [
        a: [true,false,nil],
        b: "hallo world",
        c: [
          x: [1,2,3],
          y: [{}],
          z: [[[]]]
        ]
      ]
    )
  end
  
  test "encode compound object" do
    assert(JSX.encode!([
        a: [true,false,nil],
        b: "hallo world",
        c: [
          x: [1,2,3],
          y: [{}],
          z: [[[]]]
        ]
      ]) == 
      "{\"a\":[true,false,null],\"b\":\"hallo world\",\"c\":{\"x\":[1,2,3],\"y\":{},\"z\":[[[]]]}}"
    )
  end
  
  defrecord SimpleRecord, name: nil, rank: nil
  
  test "encode a simple record" do
    assert(JSX.encode!(SimpleRecord.new(name: "Walder Frey", rank: "Lord"))
      == "{\"name\":\"Walder Frey\",\"rank\":\"Lord\"}")
  end
  
  defrecord BasicRecord, name: nil, rank: nil
  
  defimpl JSXEncoder, for: BasicRecord do
    def json(record) do
      [:start_object, "name", record.rank <> " " <> record.name, :end_object]
    end
  end
  
  test "encode a basic record with a protocol defined" do
    assert(JSX.encode!(BasicRecord.new(name: "Walder Frey", rank: "Lord"))
      == "{\"name\":\"Lord Walder Frey\"}")
  end
  
end

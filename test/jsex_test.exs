Code.require_file "test_helper.exs", __DIR__

defmodule JSEXTest do
  use ExUnit.Case

  test "decode empty object" do
    assert(JSEX.decode!("{}") == [{}])
  end
  
  test "encode empty object" do
    assert(JSEX.encode!([{}]) == "{}")
  end
  
  test "decode empty list" do
    assert(JSEX.decode!("[]") == [])
  end

  test "encode empty list" do
    assert(JSEX.encode!([]) == "[]")
  end
  
  test "encode list of empty lists" do
    assert(JSEX.encode!([[], [], []]) == "[[],[],[]]")
  end
  
  test "encode list of empty objects" do
    assert(JSEX.encode!([[{}], [{}], [{}]]) == "[{},{},{}]")
  end
  
  test "decode literals" do
    assert(JSEX.decode!("[true, false, null]") == [true, false, nil])
  end
  
  test "encode literals" do
    assert(JSEX.encode!([true, false, nil]) == "[true,false,null]")
  end
  
  test "decode numbers" do
    assert(
      JSEX.decode!("[-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617]")
        == [-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617]
      )
  end
  
  test "encode numbers" do
    assert(
      JSEX.encode!([-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617])
        == "[-18446744073709551617,-1.0,-1,0,0.0,1,1.0,18446744073709551617]"
      )
  end
  
  test "decode strings" do
    assert(JSEX.decode!("[\"hallo\", \"world\"]") == ["hallo", "world"])
  end

  test "encode strings" do
    assert(JSEX.encode!(["hallo", "world"]) == "[\"hallo\",\"world\"]")
  end
  
  test "decode simple object" do
    assert(JSEX.decode!("{\"key\": true}") == [{"key", true}])
  end
  
  test "encode simple object" do
    assert(JSEX.encode!([key: true]) == "{\"key\":true}")
  end
  
  test "decode compound object" do
    assert(JSEX.decode!(
      "{\"a\": [ true, false, null ], \"b\": \"hallo world\", \"c\": {
        \"x\": [ 1,2,3 ], \"y\": {}, \"z\": [[[]]]
      }}") == [
        {"a", [true,false,nil]},
        {"b", "hallo world"},
        {"c", [
          {"x", [1,2,3]},
          {"y", [{}]},
          {"z", [[[]]]}
        ]}
      ]
    )
  end
  
  test "encode compound object" do
    assert(JSEX.encode!([
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
    assert(JSEX.encode!(SimpleRecord.new(name: "Walder Frey", rank: "Lord"))
      == "{\"name\":\"Walder Frey\",\"rank\":\"Lord\"}")
  end
  
  defrecord BasicRecord, name: nil, rank: nil
  
  defimpl JSEX.Encoder, for: BasicRecord do
    def json(record) do
      [:start_object, "name", record.rank <> " " <> record.name, :end_object]
    end
  end
  
  test "encode a basic record with a protocol defined" do
    assert(JSEX.encode!(BasicRecord.new(name: "Walder Frey", rank: "Lord"))
      == "{\"name\":\"Lord Walder Frey\"}")
  end
  
end

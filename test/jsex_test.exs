Code.require_file "test_helper.exs", __DIR__

defmodule JSEX.Tests.Helpers do
  def numbers(:ex), do: [-18446744073709551617, -1.0, -1, 0, 0.0, 1, 1.0, 18446744073709551617]
  def numbers(:json), do: "[-18446744073709551617,-1.0,-1,0,0.0,1,1.0,18446744073709551617]"

  def compoundobj(:ex) do
    %{
      "a" => [true,false,nil],
      "b" => "hallo world",
      "c" => %{
        "x" => [1,2,3],
        "y" => %{},
        "z" => [[[]]]
      }
    }
  end
  def compoundobj(:json), do: "{\"a\":[true,false,null],\"b\":\"hallo world\",\"c\":{\"x\":[1,2,3],\"y\":{},\"z\":[[[]]]}}"
end

defmodule JSEX.Tests.Decode do
  use ExUnit.Case
  import JSEX.Tests.Helpers

  test "decode empty object" do
    assert(JSEX.decode("{}") == { :ok, %{} })
  end

  test "decode! empty object" do
    assert(JSEX.decode!("{}") == %{})
  end

  test "decode empty list" do
    assert(JSEX.decode("[]") == { :ok, [] })
  end

  test "decode! empty list" do
    assert(JSEX.decode!("[]") == [])
  end

  test "decode literals" do
    assert(JSEX.decode("[true, false, null]") == { :ok, [true, false, nil] })
  end

  test "decode! literals" do
    assert(JSEX.decode!("[true, false, null]") == [true, false, nil])
  end

  test "decode numbers" do
    assert(JSEX.decode(numbers(:json)) == { :ok, numbers(:ex) })
  end

  test "decode! numbers" do
    assert(JSEX.decode!(numbers(:json)) == numbers(:ex))
  end

  test "decode strings" do
    assert(JSEX.decode("[\"hallo\", \"world\"]") == { :ok, ["hallo", "world"] })
  end

  test "decode! strings" do
    assert(JSEX.decode!("[\"hallo\", \"world\"]") == ["hallo", "world"])
  end

  test "decode simple object" do
    assert(JSEX.decode("{\"key\": true}") == { :ok, %{"key" => true} })
  end

  test "decode! simple object" do
    assert(JSEX.decode!("{\"key\": true}") == %{"key" => true})
  end

  test "decode compound object" do
    assert(JSEX.decode(compoundobj(:json)) == { :ok, compoundobj(:ex) })
  end

  test "decode! compound object" do
    assert(JSEX.decode!(compoundobj(:json)) == compoundobj(:ex))
  end
end

defmodule JSEX.Tests.Encode do
  use ExUnit.Case
  import JSEX.Tests.Helpers

  test "encode empty object (list)" do
    assert(JSEX.encode([{}]) == { :ok, "{}" })
  end

  test "encode! empty object (list)" do
    assert(JSEX.encode!([{}]) == "{}")
  end

  test "encode empty object (map)" do
    assert(JSEX.encode(%{}) == { :ok, "{}" })
  end

  test "encode! empty object (map)" do
    assert(JSEX.encode!(%{}) == "{}")
  end

  test "encode empty list" do
    assert(JSEX.encode([]) == { :ok, "[]" })
  end

  test "encode! empty list" do
    assert(JSEX.encode!([]) == "[]")
  end

  test "encode list of empty lists" do
    assert(JSEX.encode([[], [], []]) == { :ok, "[[],[],[]]" })
  end

  test "encode! list of empty lists" do
    assert(JSEX.encode!([[], [], []]) == "[[],[],[]]")
  end

  test "encode list of empty objects" do
    assert(JSEX.encode([%{}, %{}, %{}]) == { :ok, "[{},{},{}]" })
  end

  test "encode! list of empty objects" do
    assert(JSEX.encode!([%{}, %{}, %{}]) == "[{},{},{}]")
  end

  test "encode literals" do
    assert(JSEX.encode([true, false, nil]) == { :ok, "[true,false,null]" })
  end

  test "encode! literals" do
    assert(JSEX.encode!([true, false, nil]) == "[true,false,null]")
  end

  test "encode numbers" do
    assert(JSEX.encode(numbers(:ex)) == { :ok, numbers(:json) })
  end

  test "encode! numbers" do
    assert(JSEX.encode!(numbers(:ex)) == numbers(:json))
  end

  test "encode strings" do
    assert(JSEX.encode(["hallo", "world"]) == { :ok, "[\"hallo\",\"world\"]" })
  end

  test "encode! strings" do
    assert(JSEX.encode!(["hallo", "world"]) == "[\"hallo\",\"world\"]")
  end

  test "encode keylist" do
    assert(JSEX.encode([key: true]) == { :ok, "{\"key\":true}" })
  end

  test "encode! keylist" do
    assert(JSEX.encode!([key: true]) == "{\"key\":true}")
  end

  test "encode map" do
    assert(JSEX.encode(%{ "key" => true }) == { :ok, "{\"key\":true}" })
  end

  test "encode! map" do
    assert(JSEX.encode!(%{ "key" => true }) == "{\"key\":true}")
  end

  test "encode HashDict" do
    assert(JSEX.encode(Enum.into([key: true], HashDict.new)) == { :ok, "{\"key\":true}" })
  end

  test "encode! HashDict" do
    assert(JSEX.encode!(Enum.into([key: true], HashDict.new)) == "{\"key\":true}")
  end

  test "encode object with bitstring key" do
    assert(JSEX.encode(%{ "key" => true }) == { :ok, "{\"key\":true}" })
  end

  test "encode! object with bitstring key" do
    assert(JSEX.encode!(%{ "key" => true }) == "{\"key\":true}")
  end

  test "encode object with atom key" do
    assert(JSEX.encode(%{ :key => true }) == { :ok, "{\"key\":true}" })
  end

  test "encode! object with atom key" do
    assert(JSEX.encode!(%{ :key => true }) == "{\"key\":true}")
  end

  test "encode compound object" do
    assert(JSEX.encode(compoundobj(:ex)) == { :ok, compoundobj(:json) })
  end

  test "encode! compound object" do
    assert(JSEX.encode!(compoundobj(:ex)) == compoundobj(:json))
  end
  
  test "encode keylist with key `nil`" do
    assert(JSEX.encode([nil: nil]) == { :ok, "{\"nil\":null}" })
  end
  
  test "encode map with key `nil`" do
    assert(JSEX.encode(%{ nil => nil }) == { :ok, "{\"nil\":null}" })
  end
  
  test "encode HashDict with key `nil`" do
    assert(JSEX.encode(Enum.into([nil: nil], HashDict.new)) == { :ok, "{\"nil\":null}" })
  end
end

defmodule User do
  defstruct name: "jose", age: 27
end

defmodule FancyUser do
  defstruct name: "jose", age: 27
end

defimpl JSEX.Encoder, for: FancyUser do
  def json(user) do
    [Map.get(user, :name) <> " is " <> to_string(Map.get(user, :age)) <> " years old!"]
  end
end

defmodule JSEX.Tests.Structs do
  use ExUnit.Case

  test "encode a simple struct" do
    assert(JSEX.encode(%User{}) == { :ok, "{\"age\":27,\"name\":\"jose\"}" })
  end

  test "encode a list of simple structs" do
    assert(JSEX.encode([%User{}]) == { :ok, "[{\"age\":27,\"name\":\"jose\"}]" })
  end

  test "encode a struct with a protocol defined" do
    assert(JSEX.encode(%FancyUser{}) == { :ok, "\"jose is 27 years old!\"" })
  end
end

defmodule JSEX.Tests.Is do
  use ExUnit.Case

  test "is_json? {}", do: assert(JSEX.is_json?("{}") == true)
  test "is_json? {", do: assert(JSEX.is_json?("{") == false)
  test "is_json? :error", do: assert(JSEX.is_json?(:error) == false)

  test "is_term? [{}]", do: assert(JSEX.is_term?([{}]) == true)
  test "is_term? %{}", do: assert(JSEX.is_term?(%{}) == true)
  test "is_term? {}", do: assert(JSEX.is_term?({}) == false)
  test "is_term? self", do: assert(JSEX.is_term?(self()) == false)
end

defmodule JSEX.Tests.Errors do
  use ExUnit.Case

  test "decode {", do: assert(JSEX.decode("{") == { :error, :badarg })
  test "decode! {", do: assert_raise(ArgumentError, fn -> JSEX.decode!("{") end)

  test "format {", do: assert(JSEX.format("{") == { :error, :badarg })
  test "format! {", do: assert_raise(ArgumentError, fn -> JSEX.format!("{") end)

  test "decode :error", do: assert(JSEX.decode(:error) == { :error, :badarg })
  test "decode! :error", do: assert_raise(ArgumentError, fn -> JSEX.decode!(:error) end)

  test "format :error", do: assert(JSEX.format(:error) == { :error, :badarg })
  test "format! :error", do: assert_raise(ArgumentError, fn -> JSEX.format!(:error) end)

  test "encode self", do: assert(JSEX.encode(self) == { :error, :badarg })
  test "encode! self", do: assert_raise(ArgumentError, fn -> JSEX.encode!(self) end)
end
